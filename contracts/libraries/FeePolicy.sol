// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Math.sol";

type FeePolicy is uint24;

library FeePolicyLibrary {
    uint256 internal constant RATE_PRECISION = 10 ** 6;
    int256 internal constant MAX_FEE_RATE = 500000;
    int256 internal constant MIN_FEE_RATE = -500000;

    uint256 internal constant RATE_MASK = 0x7fffff; // 23 bits

    error InvalidFeePolicy();

    function encode(bool usesQuote_, int24 rate_) internal pure returns (FeePolicy feePolicy) {
        if (rate_ > MAX_FEE_RATE || rate_ < MIN_FEE_RATE) {
            revert InvalidFeePolicy();
        }

        uint256 mask = usesQuote_ ? 1 << 23 : 0;
        assembly {
            feePolicy := or(mask, add(rate_, MAX_FEE_RATE))
        }
    }

    function isValid(FeePolicy self) internal pure returns (bool) {
        int24 r = rate(self);

        return !(r > MAX_FEE_RATE || r < MIN_FEE_RATE);
    }

    function usesQuote(FeePolicy self) internal pure returns (bool f) {
        assembly {
            f := shr(23, self)
        }
    }

    function rate(FeePolicy self) internal pure returns (int24 r) {
        assembly {
            r := sub(and(self, RATE_MASK), MAX_FEE_RATE)
        }
    }

    function calculateFee(FeePolicy self, uint256 amount, bool reverse) internal pure returns (int256 fee) {
        int24 r = rate(self);

        bool positive = r > 0;
        uint256 absRate;
        unchecked {
            absRate = uint256(uint24(positive ? r : -r));
        }
        // @dev absFee must be less than type(int256).max
        uint256 absFee = Math.divide(amount * absRate, RATE_PRECISION, reverse ? !positive : positive);
        fee = positive ? int256(absFee) : -int256(absFee);
    }
}
