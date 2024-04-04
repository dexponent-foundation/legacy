// This abstract contract defines two modifiers that are commonly used throughout the system:
// 1. ZeroAmount: Ensures that a given uint256 amount is greater than zero. It is used to prevent functions from accepting zero or negative amounts.
// 2. ZeroAddress: Ensures that a given address is not the zero address (address(0)). It is used to prevent functions from operating with an invalid or uninitialized address.
abstract contract Modifiers {
    // Modifier: ZeroAmount
    // Purpose: Ensures that the provided amount is greater than zero.
    // Parameters:
    // - amount: The uint256 amount to check.
    modifier ZeroAmount(uint256 amount) {
        require(amount > 0, "Amount cannot be zero");
        _;
    }

    // Modifier: ZeroAddress
    // Purpose: Ensures that the provided address is not the zero address.
    // Parameters:
    // - account: The address to check.
    modifier ZeroAddress(address account) {
        require(account != address(0), "Address cannot be zero");
        _;
    }
}
