## Chunker Service

- Deploy the chunker service:

```
oc apply -f deploy.yaml
```

- port forward

```
oc port-forward service/chunker-service 8085:8085
```


## Sample Requests

### List available endpoints

```
grpcurl \
  -plaintext \
  localhost:8085 \
  list
```

- expected output: 

```
caikit.runtime.Chunkers.ChunkersService
grpc.health.v1.Health
grpc.reflection.v1alpha.ServerReflection
```

### Health check

```
grpcurl \
    -plaintext \
    localhost:8085 \
    grpc.health.v1.Health/Check
```

- expected output: 

```
  grpc.health.v1.Health/Check
{
  "status": "SERVING"
}
```
### Test sentence chunker


```
grpcurl \
    -plaintext \
    -H "mm-model-id: sentence" \
    -d '{"text": "Hello world. This is a test. This is a yet another test"}' \
    localhost:8085 \
    caikit.runtime.Chunkers.ChunkersService/ChunkerTokenizationTaskPredict
```

- expected output

```
{
  "results": [
    {
      "end": "12",
      "text": "Hello world."
    },
    {
      "start": "13",
      "end": "28",
      "text": "This is a test."
    },
    {
      "start": "29",
      "end": "55",
      "text": "This is a yet another test"
    }
  ],
  "token_count": "3"
}
```

### Test langchain_character chunker

```
grpcurl \
    -plaintext \
    -H "mm-model-id: langchain_character" \
    -d '{
        "text": "First paragraph of a very long document to demonstrate how this chunking algorithm would work; we set the chunk sizes to be of max size of xxx characters with no overlap.\n\nSecond paragraph.\n\nThird paragraph."
    }' \
    localhost:8085 \
    caikit.runtime.Chunkers.ChunkersService/ChunkerTokenizationTaskPredict
```

- expected output

```
{
  "results": [
    {
      "end": "170",
      "text": "First paragraph of a very long document to demonstrate how this chunking algorithm would work; we set the chunk sizes to be of max size of xxx characters with no overlap."
    },
    {
      "start": "172",
      "end": "207",
      "text": "Second paragraph.\n\nThird paragraph."
    }
  ],
  "token_count": "2"
}
```

### Test langchain_recursive_character chunker

```
grpcurl \
    -plaintext \
    -H "mm-model-id: langchain_recursive_character" \
    -d '{
        "text": "First paragraph of a very long document to demonstrate how this chunking algorithm would work; we set the chunk sizes to be of max size of xxx characters with no overlap.\n\nSecond paragraph.\n\nThird paragraph."
    }' \
    localhost:8085 \
    caikit.runtime.Chunkers.ChunkersService/ChunkerTokenizationTaskPredict
```

- expected output

```
{
  "results": [
    {
      "end": "97",
      "text": "First paragraph of a very long document to demonstrate how this chunking algorithm would work; we"
    },
    {
      "start": "98",
      "end": "170",
      "text": "set the chunk sizes to be of max size of xxx characters with no overlap."
    },
    {
      "start": "172",
      "end": "207",
      "text": "Second paragraph.\n\nThird paragraph."
    }
  ],
  "token_count": "3"
}
```