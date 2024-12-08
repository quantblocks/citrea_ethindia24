// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library TWAPLib {
    struct TWAPData {
        uint256 cumulativePrice;
        uint256 lastTimestamp;
        uint256 lastPrice;
    }

    function updateTWAP(TWAPData storage self, uint256 currentPrice) internal {
        uint256 timeElapsed = block.timestamp - self.lastTimestamp;
        if (self.lastTimestamp == 0) {
            self.lastTimestamp = block.timestamp;
            self.lastPrice = currentPrice;
        } else if (timeElapsed > 0) {
            self.cumulativePrice += self.lastPrice * timeElapsed;
            self.lastTimestamp = block.timestamp;
            self.lastPrice = currentPrice;
        }
    }

    function getTWAP(TWAPData storage self) internal view returns (uint256) {
        if (self.lastTimestamp == 0) {
            return self.lastPrice;
        }
        uint256 timeElapsed = block.timestamp - self.lastTimestamp;
        uint256 cumPrice = self.cumulativePrice + (self.lastPrice * timeElapsed);
        uint256 totalTime = (block.timestamp - (self.lastTimestamp == 0 ? block.timestamp : self.lastTimestamp)) + timeElapsed;
        if (totalTime == 0) return self.lastPrice;
        return cumPrice / totalTime;
    }
}
