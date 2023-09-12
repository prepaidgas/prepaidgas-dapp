// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

struct Order {
  address creator;
  uint256 maxGas;
  uint256 maxGasPrice;
  uint256 executionPeriodStart;
  uint256 executionPeriodDeadline;
  uint256 executionWindow;
  bool isRevokable;
}

enum OrderStatus {
  None,
  Pending,
  Accepted,
  Active,
  Inactive, // @notice the order might be inactive due to exhausted gas limit or execution time
  Closed
}

struct GasPayment {
  address token;
  uint256 gasPrice;
}

struct Payment {
  address token;
  uint256 amount;
}

interface IGasOrder {
  function reportExecution(
    uint256 id,
    address signer,
    address onBehalf,
    uint256 gasLimit,
    address fulfiller,
    uint256 gasSpent
  ) external;
}
