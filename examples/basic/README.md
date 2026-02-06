# Basic Example

Net with two public subnets, an Internet Service, and a public route table.

## Usage

```bash
tofu init
tofu plan
tofu apply
```

## What This Creates

- 1 Net (`10.0.0.0/16`)
- 2 Subnets across two subregions (`eu-west-2a`, `eu-west-2b`)
- 1 Internet Service attached to the Net
- 1 Route Table with a default route to the Internet Service
- Route table associated with both subnets
