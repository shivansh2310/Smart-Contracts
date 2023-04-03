pragma solidity ^0.8.0;

import { FlashLoanReceiverBase } from "./FlashLoanReceiverBase.sol";
import { IERC20, IUniswapV2Router02 } from "./Interfaces.sol";

contract FlashLoanArbitrage is FlashLoanReceiverBase {

    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Router02 public immutable sushiswapRouter;

    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        sushiswapRouter = IUniswapV2Router02(SUSHISWAP_ROUTER_ADDRESS);
    }

    function startFlashLoanArbitrage(address token, uint256 amount) external {
        bytes memory data = abi.encode(token, amount);
        executeOperation(token, amount, 0, data);
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        require(msg.sender == address(lendingPool), "caller is not lending pool");

        (address token, uint256 amount) = abi.decode(_params, (address, uint256));
        
        // Perform Arbitrage Trade
        IERC20 tokenContract = IERC20(token);
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        
        // Swap tokens on Uniswap
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();
        uint[] memory amounts = uniswapRouter.swapExactTokensForETH(
            tokenBalance,
            0,
            path,
            address(this),
            block.timestamp + 1800
        );
        uint256 ethBalance = amounts[1];

        // Swap tokens on Sushiswap
        path[1] = sushiswapRouter.WETH();
        uint256[] memory amountsOut = sushiswapRouter.getAmountsOut(ethBalance, path);
        uint256 sushiAmount = amountsOut[1];
        sushiswapRouter.swapETHForExactTokens{ value: ethBalance }(
            sushiAmount,
            path,
            address(this),
            block.timestamp + 1800
        );

        // Repay flash loan with fee
        uint256 totalDebt = _amount.add(_fee);
        tokenContract.approve(address(lendingPool), totalDebt);
    }
}
