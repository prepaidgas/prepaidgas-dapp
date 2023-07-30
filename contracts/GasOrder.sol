// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IGasOrder} from "./interfaces/IGasOrder.sol";
import {FeeProcessor} from "./tools/FeeProcessor.sol";
import {PaymentMethods} from "./tools/PaymentMethods.sol";
import {Distributor} from "./tools/Distributor.sol";
import {ERC1155ish} from "./base/ERC1155ish.sol";
import {Order, OrderStatus, GasPayment, Payment, IGasOrder} from "./interfaces/IGasOrder.sol";

import "./common/Errors.sol" as Error;

/**
 * @title GasOrder
 * @notice This contract manages the deposit for Gas orders
 * @dev It is recomended to deploy the contract to the cheep network
 * @author SteMak, markfender
 */

contract GasOrder is IGasOrder, FeeProcessor, PaymentMethods, Distributor, ERC1155ish {
  using SafeERC20 for IERC20;

  address public immutable execution;

  uint256 public orders;
  mapping(uint256 => Order) public order;

  mapping(uint256 => Payment) public reward;
  mapping(uint256 => GasPayment) public prepay;
  mapping(uint256 => GasPayment) public guarantee;

  mapping(uint256 => address) public executor;

  event OrderCreate(uint256 id);
  event OrderAccept(uint256 id, address executor);

  modifier executionCallback() {
    if (execution != msg.sender) revert Error.Unauthorized(msg.sender, execution);
    _;
  }

  modifier deadlineNotMet(uint256 deadline) {
    if (deadline <= block.timestamp) revert Error.DeadlineExpired(block.timestamp, deadline);
    _;
  }

  constructor(address executionEndpoint) {
    execution = executionEndpoint;
  }

  function createOrder(
    uint256 maxGas,
    uint256 deadline,
    Payment memory rewardValue,
    GasPayment calldata prepayValue,
    GasPayment calldata guaranteeValue
  )
    external
    deadlineNotMet(deadline)
    paymentMethod(rewardValue.token)
    paymentMethod(prepayValue.token)
    paymentMethod(guaranteeValue.token)
  {
    uint256 id = orders++;

    _mint(msg.sender, id, maxGas);

    order[id] = Order({deadline: deadline});

    rewardValue.amount = _takeFee(rewardValue.token, rewardValue.amount);

    reward[id] = rewardValue;
    prepay[id] = prepayValue;
    guarantee[id] = guaranteeValue;

    IERC20(rewardValue.token).safeTransferFrom(msg.sender, address(this), rewardValue.amount);
    IERC20(prepayValue.token).safeTransferFrom(msg.sender, address(this), prepayValue.gasPrice * maxGas);

    emit OrderCreate(id);
  }

  function acceptOrder(uint256 id) public {
    if (status(id) != OrderStatus.Pending) revert Error.WrongOrderStatus(OrderStatus.Pending);

    executor[id] = msg.sender;

    IERC20(guarantee[id].token).safeTransferFrom(msg.sender, address(this), totalSupply(id) * guarantee[id].gasPrice);
    IERC20(reward[id].token).safeTransfer(msg.sender, reward[id].amount);

    emit OrderAccept(id, msg.sender);
  }

  function retrievePrepay(uint256 id, uint256 amount) external {
    _utilize(msg.sender, msg.sender, id, amount);

    IERC20(prepay[id].token).safeTransfer(msg.sender, prepay[id].gasPrice * amount);
    if (executor[id] != address(0)) _distribute(executor[id], guarantee[id].token, guarantee[id].gasPrice * amount);
  }

  function retrieveGuarantee(uint256 id) external {
    if (status(id) != OrderStatus.Exhausted) revert Error.WrongOrderStatus(OrderStatus.Exhausted);

    _distribute(executor[id], guarantee[id].token, guarantee[id].gasPrice * totalSupply(id));
    executor[id] = address(0);
  }

  function reportExecution(
    uint256 id,
    address signer,
    address onBehalf,
    uint256 gasLimit,
    address fulfiller,
    uint256 gasSpent
  ) external executionCallback {
    // @todo implement infrastructure gas constant and add to gasLimit
    uint256 balance = usable(onBehalf, id, signer);
    if (gasLimit > balance) revert Error.GasLimitExceedBalance(gasLimit, balance);

    // @todo gasSpent should be <= gasLimit !!!
    _utilize(onBehalf, signer, id, gasSpent);

    if (fulfiller == address(0)) fulfiller = executor[id];

    uint256 unlock = guarantee[id].gasPrice * gasSpent;
    address unlockToken = guarantee[id].token;
    _distribute(fulfiller, unlockToken, fulfiller != executor[id] ? _takeFee(unlockToken, unlock) : unlock);
    _distribute(fulfiller, prepay[id].token, prepay[id].gasPrice * gasSpent);
  }

  function status(uint256 id) public view returns (OrderStatus) {
    if (totalSupply(id) == 0) return OrderStatus.Fulfilled;
    if (executor[id] == address(0) && order[id].deadline < block.timestamp) return OrderStatus.Fulfilled;

    if (order[id].deadline < block.timestamp) return OrderStatus.Exhausted;

    if (executor[id] == address(0)) return OrderStatus.Pending;

    return OrderStatus.Active;
  }
}
