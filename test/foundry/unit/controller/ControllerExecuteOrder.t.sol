// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../Constants.sol";
import "../../../../contracts/libraries/BookId.sol";
import "../../../../contracts/libraries/Hooks.sol";
import "../../../../contracts/Controller.sol";
import "../../../../contracts/BookManager.sol";
import "../../mocks/MockERC20.sol";

contract ControllerExecuteOrderTest is Test {
    using TickLibrary for Tick;
    using OrderIdLibrary for OrderId;
    using BookIdLibrary for IBookManager.BookKey;
    using Hooks for IHooks;

    MockERC20 public mockErc20;

    IBookManager.BookKey public key;
    IBookManager.BookKey public unopenedKey;
    IBookManager public manager;
    Controller public controller;
    OrderId public orderId1;

    function setUp() public {
        mockErc20 = new MockERC20("Mock", "MOCK", 18);

        key = IBookManager.BookKey({
            base: Currency.wrap(address(mockErc20)),
            unit: 1e12,
            quote: CurrencyLibrary.NATIVE,
            makerPolicy: FeePolicyLibrary.encode(true, 0),
            takerPolicy: FeePolicyLibrary.encode(true, 0),
            hooks: IHooks(address(0))
        });
        unopenedKey = key;
        unopenedKey.unit = 1e11;

        manager = new BookManager(address(this), Constants.DEFAULT_PROVIDER, "baseUrl", "contractUrl", "name", "symbol");
        manager.open(key, "");

        controller = new Controller(address(manager));

        vm.deal(Constants.MAKER1, 1000 * 10 ** 18);
        vm.deal(Constants.MAKER2, 1000 * 10 ** 18);
        vm.deal(Constants.MAKER3, 1000 * 10 ** 18);

        vm.deal(Constants.TAKER1, 1000 * 10 ** 18);
        mockErc20.mint(Constants.TAKER1, 1000 * 10 ** 18);

        IController.MakeOrderParams[] memory paramsList = new IController.MakeOrderParams[](1);
        IController.ERC20PermitParams[] memory relatedTokenList;
        paramsList[0] = _makeOrder(Constants.PRICE_TICK, Constants.QUOTE_AMOUNT3);

        vm.prank(Constants.MAKER1);
        orderId1 =
            controller.make{value: Constants.QUOTE_AMOUNT3}(paramsList, relatedTokenList, uint64(block.timestamp))[0];
    }

    function _makeOrder(int24 tick, uint256 quoteAmount)
        internal
        view
        returns (IController.MakeOrderParams memory params)
    {
        params = IController.MakeOrderParams({
            id: key.toId(),
            tick: Tick.wrap(tick),
            quoteAmount: quoteAmount,
            claimBounty: 0,
            hookData: ""
        });

        return params;
    }

    function _takeOrder(uint256 quoteAmount, uint256 maxBaseAmount)
        internal
        view
        returns (IController.TakeOrderParams memory params)
    {
        params = IController.TakeOrderParams({
            id: key.toId(),
            limitPrice: type(uint256).max,
            quoteAmount: quoteAmount,
            maxBaseAmount: maxBaseAmount,
            hookData: ""
        });

        return params;
    }

    function _spendOrder(uint256 baseAmount, uint256 minQuoteAmount)
        internal
        view
        returns (IController.SpendOrderParams memory params)
    {
        params = IController.SpendOrderParams({
            id: key.toId(),
            limitPrice: type(uint256).max,
            baseAmount: baseAmount,
            minQuoteAmount: minQuoteAmount,
            hookData: ""
        });
    }

    function _claimOrder(OrderId id) internal pure returns (IController.ClaimOrderParams memory) {
        IController.PermitSignature memory signature;
        return IController.ClaimOrderParams({id: id, hookData: "", permitParams: signature});
    }

    function _cancelOrder(OrderId id) internal pure returns (IController.CancelOrderParams memory) {
        IController.PermitSignature memory signature;
        return IController.CancelOrderParams({id: id, leftQuoteAmount: 0, hookData: "", permitParams: signature});
    }

    function testExecuteOrder() public {
        IController.Action[] memory actionList = new IController.Action[](3);
        actionList[0] = IController.Action.MAKE;
        actionList[1] = IController.Action.TAKE;
        actionList[2] = IController.Action.SPEND;

        bytes[] memory paramsDataList = new bytes[](3);
        paramsDataList[0] = abi.encode(_makeOrder(Constants.PRICE_TICK + 2, Constants.QUOTE_AMOUNT2));
        paramsDataList[1] = abi.encode(_takeOrder(Constants.QUOTE_AMOUNT2, type(uint256).max));
        paramsDataList[2] = abi.encode(_spendOrder(Constants.BASE_AMOUNT1, 0));

        IController.ERC20PermitParams[] memory relatedTokenList = new IController.ERC20PermitParams[](1);
        IController.PermitSignature memory signature;
        relatedTokenList[0] =
            IController.ERC20PermitParams({token: address(mockErc20), permitAmount: 0, signature: signature});

        uint256 beforeBalance = Constants.TAKER1.balance;
        uint256 beforeTokenBalance = mockErc20.balanceOf(Constants.TAKER1);

        vm.startPrank(Constants.TAKER1);
        mockErc20.approve(address(controller), type(uint256).max);
        OrderId orderId2 = controller.execute{value: Constants.QUOTE_AMOUNT2}(
            actionList, paramsDataList, relatedTokenList, uint64(block.timestamp)
        )[0];
        vm.stopPrank();

        uint256 quoteAmount = 152000001000000000000 + 15956916000000000000 - 152000000000000000000;
        assertEq(Constants.TAKER1.balance - beforeBalance, quoteAmount);
        uint256 takeAmount = Tick.wrap(Constants.PRICE_TICK).quoteToBase(94000000000000000000, true)
            + Tick.wrap(Constants.PRICE_TICK + 2).quoteToBase(58000001000000000000, true)
            + Tick.wrap(Constants.PRICE_TICK + 2).quoteToBase(15956916000000000000, true);

        assertEq(beforeTokenBalance - mockErc20.balanceOf(Constants.TAKER1), takeAmount);

        actionList = new IController.Action[](2);
        actionList[0] = IController.Action.CLAIM;
        actionList[1] = IController.Action.CANCEL;

        paramsDataList = new bytes[](2);
        paramsDataList[0] = abi.encode(_claimOrder(orderId1));
        paramsDataList[1] = abi.encode(_cancelOrder(orderId2));

        beforeBalance = Constants.TAKER1.balance;
        beforeTokenBalance = mockErc20.balanceOf(Constants.MAKER1);

        vm.startPrank(Constants.TAKER1);
        manager.approve(address(controller), OrderId.unwrap(orderId2));
        controller.execute(actionList, paramsDataList, relatedTokenList, uint64(block.timestamp));
        vm.stopPrank();

        assertEq(Constants.TAKER1.balance - beforeBalance, 78043083000000000000);
        assertEq(mockErc20.balanceOf(Constants.MAKER1) - beforeTokenBalance, 70704485945479345753);
    }
}
