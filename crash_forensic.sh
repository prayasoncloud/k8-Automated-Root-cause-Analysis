#!/bin/bash

PODS=$(kubectl get pods --all-namespaces --no-headers | \
awk '$1 != "kube-system" && $4 ~ /CrashLoopBackOff|Error|ImagePullBackOff/')

if [ -z "$PODS" ]; then
    echo "No problematic pods found"
    exit 0
fi

echo "$PODS" | while read -r NAMESPACE POD READY STATUS RESTARTS AGE
do

    NODE=$(kubectl get pod "$POD" -n "$NAMESPACE" \
        -o jsonpath='{.spec.nodeName}' 2>/dev/null)

    WAITING_REASON=$(kubectl get pod "$POD" -n "$NAMESPACE" \
        -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)

    TERM_REASON=$(kubectl get pod "$POD" -n "$NAMESPACE" \
        -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}' 2>/dev/null)

    EXIT_CODE=$(kubectl get pod "$POD" -n "$NAMESPACE" \
        -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}' 2>/dev/null)

    EVENTS=$(kubectl get events -n "$NAMESPACE" \
        --field-selector involvedObject.name="$POD" \
        --sort-by=.metadata.creationTimestamp 2>/dev/null)

    LOGS=$(kubectl logs "$POD" -n "$NAMESPACE" --previous 2>/dev/null)

    ROOT_CAUSE="Unknown"
    RECOMMENDATION="Investigate Pod manually"

    if [[ "$TERM_REASON" == "OOMKilled" || "$EXIT_CODE" == "137" ]]; then
        ROOT_CAUSE="Memory Overload"
        RECOMMENDATION="Increase the Memory limit"


    elif echo "$EVENTS" | grep -qi "Liveness probe failed"; then
        ROOT_CAUSE="Probe Failure"
        RECOMMENDATION="Check for the port, path or initialDelaySeconds"

    elif [[ "$EXIT_CODE" == "127" ]]; then
        ROOT_CAUSE="Missingcommand"
        RECOMMENDATION="Check for the  cotnainer command"

    elif [[ "$WAITING_REASON" == "ImagePullBackOff" ]]; then
        ROOT_CAUSE="Image Issue"

    elif echo "$LOGS" | grep -qi "permission denied"; then

        ROOT_CAUSE="PermissionIssue"
        RECOMMENDATION="Check for the permisons"

    elif echo "$LOGS" | grep -qi "connection refused"; then

        ROOT_CAUSE="DependencyFailure"
        RECOMMENDATION="Check for the depedencies"


    elif [[ "$EXIT_CODE" == "1" ]]; then
        ROOT_CAUSE="ApplicationError"
        RECOMMENDATION="Need to check for the Application logs or startup logs"
    fi

    echo "Pod: $POD"
    echo "Namespace: $NAMESPACE"
    echo "Status: $STATUS"
    echo "Restarts: $RESTARTS"
    echo "Node: ${NODE:-N/A}"
    echo "WaitingReason: ${WAITING_REASON:-N/A}"
    echo "TerminationReason: ${TERM_REASON:-N/A}"
    echo "ExitCode: ${EXIT_CODE:-N/A}"
    echo "RootCause: $ROOT_CAUSE"

    echo "RecentEvents:"
    echo "$EVENTS" | tail -5

    echo "PreviousLogs:"
    echo "$LOGS" | tail -20

    echo

done