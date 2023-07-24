// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IMuteSwitchPairDynamic.sol";
import "./interfaces/IMuteSwitchFactory.sol";
import "./interfaces/IMuteSwitchCallee.sol";
import "./MuteSwitchERC20Dynamic.sol";
import "./MuteSwitchFeeVault.sol";

contract MuteSwitchPairDynamic is MuteSwitchERC20Dynamic { // solhint-disable-line max-states-count
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant _SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint internal _decimals0;
    uint internal _decimals1;

    address public fees;

    uint private _reserve0;           // uses single storage slot, accessible via getReserves
    uint private _reserve1;           // uses single storage slot, accessible via getReserves
    uint private _blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public reserve0CumulativeLast;
    uint public reserve1CumulativeLast;

    uint public pairFee; // 1 = 0.01% - 1000 = 10%

    bool public stable;

    // index0 and index1 are used to accumulate fees, this is split out from normal trades to keep the swap "clean"
    // this further allows LP holders to easily claim fees for tokens they have/staked
    uint public index0 = 0;
    uint public index1 = 0;

    // position assigned to each LP to track their current index0 & index1 vs the global position
    mapping(address => uint) public supplyIndex0;
    mapping(address => uint) public supplyIndex1;

    // tracks the amount of unclaimed, but claimable tokens off of fees for token0 and token1
    mapping(address => uint) public claimable0;
    mapping(address => uint) public claimable1;


    // Structure to capture time period obervations every 30 minutes, used for local oracles
    struct Observation {
        uint timestamp;
        uint reserve0Cumulative;
        uint reserve1Cumulative;
    }

    // Capture oracle reading every 30 minutes
    uint public constant PERIOD_SIZE = 30 minutes;

    Observation[] public observations;

    uint private _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1, "MuteSwitchPair: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    function getReserves() public view returns (uint reserve0_, uint reserve1_, uint blockTimestampLast_) {
        reserve0_ = _reserve0;
        reserve1_ = _reserve1;
        blockTimestampLast_ = _blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR, to, value)); // solhint-disable-line avoid-low-level-calls
        require(success && (data.length == 0 || abi.decode(data, (bool))), "MuteSwitch: TRANSFER_FAILED");
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint reserve0, uint reserve1);
    event ChangeFee(uint256 pairFee, uint256 liqFee);

    event Claim(address indexed sender, address indexed recipient, uint amount0, uint amount1);
    event Fees(address indexed sender, uint amount0, uint amount1, uint pAmount0, uint pAmount1);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint _fee, bool _stable) external {
        require(msg.sender == factory, "MuteSwitch: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        stable = _stable;

        fees = address(new MuteSwitchFeeVault(_token0, _token1));

        _decimals0 = 10**IERC20Metadata(_token0).decimals();
        _decimals1 = 10**IERC20Metadata(_token1).decimals();

        if(_stable == false) {
          // cap at 10%
          if(_fee > 1000)
            _fee = 1000;
          // require at least 0.01% fee
          if(_fee < 1)
            _fee = 1;
        } else {
          // cap at 2.5%
          if(_fee > 250)
            _fee = 250;
          // require at least 0.01% fee
          if(_fee < 1)
            _fee = 1;
        }


        pairFee = _fee;

        if (_stable) {
            symbol = string(abi.encodePacked("sMLP (", IERC20Metadata(_token0).symbol(), "/", IERC20Metadata(_token1).symbol(), ")"));
            name = string(abi.encodePacked("Stable Mute LP (", IERC20Metadata(_token0).symbol(), "/", IERC20Metadata(_token1).symbol(), ")"));
        } else {
            symbol = string(abi.encodePacked("vMLP (", IERC20Metadata(_token0).symbol(), "/", IERC20Metadata(_token1).symbol(), ")"));
            name = string(abi.encodePacked("Volatile Mute LP (", IERC20Metadata(_token0).symbol(), "/", IERC20Metadata(_token1).symbol(), ")"));
        }


        observations.push(Observation(block.timestamp, 0, 0));
    }

    // largest liq owner can change fee type of pair
    function changeFeeType(uint _fee) external {
        uint256 voteWeight = getPriorVotes(msg.sender, block.number - 1);
        //if vote pool is greater than 50% of possible votes
        if(voteWeight >= totalSupply / 2){
          //1000 = 10%  1 = 0.01%
          if(stable == false) {
            // cap at 10%
            if(_fee > 1000)
              _fee = 1000;
            // require at least 0.01% fee
            if(_fee < 1)
              _fee = 1;
          } else {
            // cap at 2.5%
            if(_fee > 250)
              _fee = 250;
            // require at least 0.01% fee
            if(_fee < 1)
              _fee = 1;
          }

          pairFee = _fee;

          //payout fee to prevent flash loan changes
          //delagate MUST have at least 0.1% of the vote weight to payout the fee
          uint liqFee = _getProtocolFee(voteWeight, msg.sender);
          _transfer(msg.sender, IMuteSwitchFactory(factory).feeTo(), liqFee);

          emit ChangeFee(pairFee, liqFee);
        }
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint reserve0_, uint reserve1_) internal {
        uint blockTimestamp = block.timestamp;
        uint timeElapsed = blockTimestamp - _blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && reserve0_ != 0 && reserve1_ != 0) {
            reserve0CumulativeLast += reserve0_ * timeElapsed;
            reserve1CumulativeLast += reserve1_ * timeElapsed;
        }

        Observation memory _point = lastObservation();
        timeElapsed = blockTimestamp - _point.timestamp; // compare the last observation with current timestamp, if greater than 30 minutes, record a new event
        if (timeElapsed > PERIOD_SIZE) {
            observations.push(Observation(blockTimestamp, reserve0CumulativeLast, reserve1CumulativeLast));
        }
        _reserve0 = balance0;
        _reserve1 = balance1;
        _blockTimestampLast = blockTimestamp;
        emit Sync(_reserve0, _reserve1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint reserve0_, uint reserve1_,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - reserve0_;
        uint amount1 = balance1 - reserve1_;

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _updateFor(address(0));
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / reserve0_, amount1 * _totalSupply / reserve1_);
        }
        require(liquidity > 0, "MuteSwitch: INSUFFICIENT_LIQUIDITY_MINTED"); // solhint-disable-line reason-string

        _updateFor(to);
        _mint(to, liquidity);

        _update(balance0, balance1, reserve0_, reserve1_);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint reserve0_, uint reserve1_,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "MuteSwitch: INSUFFICIENT_LIQUIDITY_BURNED"); // solhint-disable-line reason-string

        _updateFor(address(this));
        _burn(address(this), liquidity);

        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, reserve0_, reserve1_);
        emit Burn(msg.sender, amount0, amount1, to);
    }


    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "MuteSwitch: INSUFFICIENT_OUTPUT_AMOUNT"); // solhint-disable-line reason-string
        (uint reserve0_, uint reserve1_,) = getReserves(); // gas savings
        require(amount0Out < reserve0_ && amount1Out < reserve1_, "MuteSwitch: INSUFFICIENT_LIQUIDITY"); // solhint-disable-line reason-string

        uint _balance0;
        uint _balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
          (address _token0, address _token1) = (token0, token1);
          require(to != _token0 && to != _token1, "MuteSwitch: INVALID_TO");
          if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
          if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
          if (data.length > 0) IMuteSwitchCallee(to).muteswitchCall(msg.sender, amount0Out, amount1Out, data);
          _balance0 = IERC20(_token0).balanceOf(address(this));
          _balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = _balance0 > reserve0_ - amount0Out ? _balance0 - (reserve0_ - amount0Out) : 0;
        uint amount1In = _balance1 > reserve1_ - amount1Out ? _balance1 - (reserve1_ - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "MuteSwitch: INSUFFICIENT_INPUT_AMOUNT"); // solhint-disable-line reason-string
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
          (address _token0, address _token1) = (token0, token1);
          if (amount0In > 0) _update0(amount0In * pairFee / 10000, _getProtocolFee(amount0In, to)); // accrue fees for token0 and move them out of pool
          if (amount1In > 0) _update1(amount1In * pairFee / 10000, _getProtocolFee(amount1In, to)); // accrue fees for token1 and move them out of pool
          _balance0 = IERC20(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - amountIn/ 10000, but doing balanceOf again as safety check
          _balance1 = IERC20(_token1).balanceOf(address(this));
          // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
          require(_k(_balance0, _balance1) >= _k(reserve0_, reserve1_), "K"); // Pair: K
        }

        _update(_balance0, _balance1, reserve0_, reserve1_);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // calculates the amount fee for a trade
    function _getProtocolFee(uint amount, address to) internal view returns (uint feeAmount){
        if(IMuteSwitchFactory(factory).feeTo() == to){
          feeAmount = 0;
          return feeAmount;
        }
        // if dynamic adjusted fees are on, use that instead of fixed fee
        if(IMuteSwitchFactory(factory).protocolFeeDynamic() != 0) {
          feeAmount = amount * (pairFee * IMuteSwitchFactory(factory).protocolFeeDynamic()) / (1000 * 10000);
        } else {
          feeAmount = amount * IMuteSwitchFactory(factory).protocolFeeFixed() / 10000;
        }
    }

    function _chargeProtocolFees() internal view returns (bool) {
        return IMuteSwitchFactory(factory).protocolFeeFixed() != 0 || IMuteSwitchFactory(factory).protocolFeeDynamic() != 0;
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - _reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - _reserve1);
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), _reserve0, _reserve1);
    }

    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint) {
        (uint reserve0_, uint reserve1_) = (_reserve0, _reserve1);
        amountIn -= amountIn * pairFee / 10000; // remove fee from amount received
        return _getAmountOut(amountIn, tokenIn, reserve0_, reserve1_);
    }

    function _getAmountOut(uint amountIn, address tokenIn, uint reserve0_, uint reserve1_) internal view returns (uint) {
        if (stable) {
            uint xy =  _k(reserve0_, reserve1_);
            reserve0_ = reserve0_ * 1e18 / _decimals0;
            reserve1_ = reserve1_ * 1e18 / _decimals1;
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (reserve0_, reserve1_) : (reserve1_, reserve0_);
            amountIn = tokenIn == token0 ? amountIn * 1e18 / _decimals0 : amountIn * 1e18 / _decimals1;
            uint y = reserveB - _get_y(amountIn+reserveA, xy, reserveB);
            return y * (tokenIn == token0 ? _decimals1 : _decimals0) / 1e18;
        } else {
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (reserve0_, reserve1_) : (reserve1_, reserve0_);
            return amountIn * reserveB / (reserveA + amountIn);
        }
    }

    function observationLength() external view returns (uint) {
        return observations.length;
    }

    function lastObservation() public view returns (Observation memory) {
        return observations[observations.length-1];
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices() public view returns (uint reserve0Cumulative, uint reserve1Cumulative, uint blockTimestamp) {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint reserve0_, uint reserve1_, uint blockTimestampLast_) = getReserves();
        if (blockTimestampLast_ != blockTimestamp) {
            // subtraction overflow is desired
            uint timeElapsed = blockTimestamp - blockTimestampLast_;
            reserve0Cumulative += reserve0_ * timeElapsed;
            reserve1Cumulative += reserve1_ * timeElapsed;
        }
    }

    // gives the current twap price measured from amountIn * tokenIn gives amountOut
    function current(address tokenIn, uint amountIn) external view returns (uint amountOut) {
        Observation memory _observation = lastObservation();
        (uint reserve0Cumulative, uint reserve1Cumulative,) = currentCumulativePrices();
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[observations.length-2];
        }

        uint timeElapsed = block.timestamp - _observation.timestamp;
        uint reserve0_ = (reserve0Cumulative - _observation.reserve0Cumulative) / timeElapsed;
        uint reserve1_ = (reserve1Cumulative - _observation.reserve1Cumulative) / timeElapsed;
        amountOut = _getAmountOut(amountIn, tokenIn, reserve0_, reserve1_);
    }


    // as per `current`, however allows user configured granularity, up to the full window size
    function quote(address tokenIn, uint amountIn, uint granularity) external view returns (uint amountOut) {
        uint [] memory _prices = sample(tokenIn, amountIn, granularity, 1);
        uint priceAverageCumulative;
        for (uint i = 0; i < _prices.length; i++) {
            priceAverageCumulative += _prices[i];
        }
        return priceAverageCumulative / granularity;
    }

    // returns a memory set of twap prices
    function prices(address tokenIn, uint amountIn, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, points, 1);
    }

    function sample(address tokenIn, uint amountIn, uint points, uint window) public view returns (uint[] memory) {
        uint[] memory _prices = new uint[](points);

        uint length = observations.length-1;
        uint i = length - (points * window);
        uint nextIndex = 0;
        uint index = 0;

        for (; i < length; i+=window) {
            nextIndex = i + window;
            uint timeElapsed = observations[nextIndex].timestamp - observations[i].timestamp;
            uint reserve0_ = (observations[nextIndex].reserve0Cumulative - observations[i].reserve0Cumulative) / timeElapsed;
            uint reserve1_ = (observations[nextIndex].reserve1Cumulative - observations[i].reserve1Cumulative) / timeElapsed;
            _prices[index] = _getAmountOut(amountIn, tokenIn, reserve0_, reserve1_);
            // index < length; length cannot overflow
            unchecked {
                index = index + 1;
            }
        }
        return _prices;
    }

    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1) {
        return (_decimals0, _decimals1, _reserve0, _reserve1, stable, token0, token1);
    }

    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    function transfer(address to, uint value) external returns (bool) {
        _updateFor(msg.sender);
        _updateFor(to);

        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }

        _updateFor(from);
        _updateFor(to);

        _transfer(from, to, value);
        return true;
    }

    // this function MUST be called on any balance changes, otherwise can be used to infinitely claim fees
    // Fees are segregated from core funds, so fees can never put liquidity at risk
    function _updateFor(address recipient) internal {
        uint _supplied = balanceOf[recipient]; // get LP balance of `recipient`
        if (_supplied > 0) {
            uint _supplyIndex0 = supplyIndex0[recipient]; // get last adjusted index0 for recipient
            uint _supplyIndex1 = supplyIndex1[recipient];
            uint _index0 = index0; // get global index0 for accumulated fees
            uint _index1 = index1;
            supplyIndex0[recipient] = _index0; // update user current position to global position
            supplyIndex1[recipient] = _index1;
            uint _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint _delta1 = _index1 - _supplyIndex1;
            if (_delta0 > 0) {
                uint _share = _supplied * _delta0 / 1e18; // add accrued difference for each supplied token
                claimable0[recipient] += _share;
            }
            if (_delta1 > 0) {
                uint _share = _supplied * _delta1 / 1e18;
                claimable1[recipient] += _share;
            }
        } else {
            supplyIndex0[recipient] = index0; // new users are set to the default global state
            supplyIndex1[recipient] = index1;
        }
    }

    // claim accumulated but unclaimed fees (viewable via claimable0 and claimable1)
    function claimFeesView(address recipient) external view returns (uint claimed0, uint /*claimed1*/) {
        uint _supplied = balanceOf[recipient]; // get LP balance of `recipient`
        if (_supplied > 0) {
            uint _supplyIndex0 = supplyIndex0[recipient]; // get last adjusted index0 for recipient
            uint _supplyIndex1 = supplyIndex1[recipient];
            uint _index0 = index0; // get global index0 for accumulated fees
            uint _index1 = index1;
            uint _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint _delta1 = _index1 - _supplyIndex1;
            if (_delta0 > 0) {
                uint _share = _supplied * _delta0 / 1e18; // add accrued difference for each supplied token
                claimed0 = claimable0[recipient] + _share;
            }
            if (_delta1 > 0) {
                uint _share = _supplied * _delta1 / 1e18;
                claimed0 = claimable1[recipient] + _share;
            }
        }
    }

    // claim accumulated but unclaimed fees (viewable via claimable0 and claimable1)
    function claimFees() external returns (uint claimed0, uint claimed1) {
        _updateFor(msg.sender);

        claimed0 = claimable0[msg.sender];
        claimed1 = claimable1[msg.sender];

        if (claimed0 > 0 || claimed1 > 0) {
            claimable0[msg.sender] = 0;
            claimable1[msg.sender] = 0;

            MuteSwitchFeeVault(fees).claimFeesFor(msg.sender, claimed0, claimed1);

            emit Claim(msg.sender, msg.sender, claimed0, claimed1);
        }
    }

    // Accrue fees on token0
    function _update0(uint amount, uint pAmount) internal {
        // all fees must be paid to protocol if charging less than standard
        if(pAmount >= amount){
          _safeTransfer(token0, IMuteSwitchFactory(factory).feeTo(), amount);
          emit Fees(msg.sender, 0, 0, amount, 0);
        } else {
          _safeTransfer(token0, IMuteSwitchFactory(factory).feeTo(), pAmount);

          _safeTransfer(token0, fees, amount - pAmount); // transfer the fees out to PairFees
          uint256 _ratio = (amount - pAmount) * 1e18 / totalSupply; // 1e18 adjustment is removed during claim
          if (_ratio > 0) {
              index0 += _ratio;
          }
          emit Fees(msg.sender, amount - pAmount, 0, pAmount, 0);
        }
    }

    // Accrue fees on token1
    function _update1(uint amount, uint pAmount) internal {
        // all fees must be paid to protocol if charging less than standard
        if(pAmount >= amount){
          _safeTransfer(token1, IMuteSwitchFactory(factory).feeTo(), amount);
          emit Fees(msg.sender, 0, 0, 0, amount);
        } else {
          _safeTransfer(token1, IMuteSwitchFactory(factory).feeTo(), pAmount);

          _safeTransfer(token1, fees, amount - pAmount); // transfer the fees out to PairFees
          uint256 _ratio = (amount - pAmount) * 1e18 / totalSupply; // 1e18 adjustment is removed during claim
          if (_ratio > 0) {
              index1 += _ratio;
          }
          emit Fees(msg.sender, 0, amount - pAmount, 0, pAmount);
        }
    }

    function _k(uint x, uint y) internal view returns (uint) {
        if (stable) {
            uint _x = x * 1e18 / _decimals0;
            uint _y = y * 1e18 / _decimals1;
            uint _a = (_x * _y) / 1e18;
            uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return _a * _b / 1e18;  // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        return x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3*x0*(y*y/1e18)/1e18+(x0*x0/1e18*x0/1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) { // solhint-disable-line func-name-mixedcase
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y; // solhint-disable-line var-name-mixedcase
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = (xy - k)*1e18/_d(x0, y);
                y = y + dy;
            } else {
                uint dy = (k - xy)*1e18/_d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }
}
