// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

// TODO: replace with import from @superfluid-finance/ethereum-contracts once released
interface IConstantFlowAgreementHook {
    struct CFAHookParams {
        address sender;
        address receiver;
        address flowOperator;
        int96 flowRate;
    }

    /// @notice A hook which executes on stream creation if the hook contract is set in the CFA
    /// @dev This should be implemented with an onlyCFA modifier, so that only the CFA can call the function
    /// @param token the streamed super token
    /// @param newFlowData the new flow data taken by the hook
    /// @return bool
    function onCreate(ISuperfluidToken token, CFAHookParams memory newFlowData)
        external
        returns (bool);

    /// @notice A hook which executes on stream update if the hook contract is set in the CFA
    /// @dev This should be implemented with an onlyCFA modifier, so that only the CFA can call the function
    /// @param token the streamed super token
    /// @param newFlowData the new flow data taken by the hook
    /// @param oldFlowRate previous flowrate
    /// @return bool
    function onUpdate(
        ISuperfluidToken token,
        CFAHookParams memory newFlowData,
        int96 oldFlowRate
    ) external returns (bool);

    /// @notice A hook which executes on stream deletion if the hook contract is set in the CFA
    /// @dev This should be implemented with an onlyCFA modifier, so that only the CFA can call the function
    /// @param token the streamed super token
    /// @param newFlowData the new flow data taken by the hook
    /// @param oldFlowRate previous flowrate
    /// @return bool
    function onDelete(
        ISuperfluidToken token,
        CFAHookParams memory newFlowData,
        int96 oldFlowRate
    ) external returns (bool);
}