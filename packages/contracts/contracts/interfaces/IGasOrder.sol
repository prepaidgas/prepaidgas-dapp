// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

struct Order {
  address manager;
  uint256 maxGas;
  uint256 maxGasPrice;
  uint256 executionPeriodStart;
  uint256 executionPeriodDeadline;
  uint256 executionWindow;
}

// @dev this structure is based on the `Order` structure, but has `id` and `status` extra fields
struct FilteredOrder {
  uint256 id;
  address manager;
  OrderStatus status;
  uint256 maxGas;
  uint256 executionPeriodStart;
  uint256 executionPeriodDeadline;
  uint256 executionWindow;
  uint256 availableGasHoldings;
  TokenAmountWithDetails reward;
  TokenAmountWithDetails gasCost;
  TokenAmountWithDetails guarantee;
}

struct TokenAmountWithDetails {
  string name;
  string symbol;
  uint256 decimals;
  address token;
  uint256 value;
}

enum OrderStatus {
  None,
  Pending,
  Accepted,
  Active,
  /// @notice the order might be inactive due to exhausted gas limit or execution time
  Inactive,
  Untaken,
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
    address from,
    address onBehalf,
    uint256 gasLimit,
    address fulfiller,
    uint256 gasSpent
  ) external;

  event OrderCreate(uint256 indexed id, uint256 executionWindow);
  event OrderAccept(uint256 indexed id, address indexed executor);
  event OrderManagerChanged(uint256 indexed id, address indexed oldManager, address indexed newManager);
}
