#!/bin/bash

echo "Starting script"

#CRASHLOOP_POD=$(kubectl get pods --all-namespaces --no-headers | grep -E "CrashLoopBackOff|Error")

CRASHLOOP_POD=$(kubectl get pods --all-namespaces --no-headers | awk '$5 ~ /CrashLoopBackOff|Error/ || $5 > 3')


if [ -z $CRASHLOOP_POD ]; then
    echo "all podsworking file properly"
    exit 0
fi

    NODE=$(kubectl get pod "$POD" -n "$NAMESPACE" \
        -o jsonpath='{.spec.nodeName}')

    # Get container waiting reason
    WAITING_REASON=$(kubectl get pod "$POD" -n "$NAMESPACE" \
        -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)

    # Get last termination reason
    TERM_REASON=$(kubectl get pod "$POD" -n "$NAMESPACE" \
        -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}' 2>/dev/null)

    # Get exit code
    EXIT_CODE=$(kubectl get pod "$POD" -n "$NAMESPACE" \
        -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}' 2>/dev/null)


    


done