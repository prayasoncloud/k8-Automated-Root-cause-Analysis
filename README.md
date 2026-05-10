# k8-Automated-Root-cause-Analysis
This lightweight tool automates the collection of logs, events, and state from failing K8s pods

k8s-crash-forensics/
├── crash_forensics.sh
├── modules/
│   ├── detect.sh
│   ├── collect.sh
│   ├── analyze.sh
│   ├── summarize.sh
│   └── utils.sh
├── reports/
└── README.md

Detect pod
    ↓
Get namespace
    ↓
Describe pod
    ↓
Get previous logs
    ↓
Extract events
    ↓
Analyze