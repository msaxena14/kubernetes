# Kafka

Working with Kafka from Kubernetes.

| File | What it is |
|---|---|
| [kafka-client-pod.yaml](kafka-client-pod.yaml) | A long-running client Pod (`apache/kafka`) to run the Kafka CLI tools from inside the cluster. Set `BOOTSTRAP_SERVERS` to your brokers. |
| [kafka-cheatsheet](kafka-cheatsheet) | Commands for inspecting brokers, topics, consumer groups and offsets. Replace `<broker>` with a real bootstrap address. |

Use the Pod when brokers are only reachable from inside the VPC or cluster:
```bash
kubectl apply -f kafka-client-pod.yaml
kubectl exec -it kafka-client -- bash
```
