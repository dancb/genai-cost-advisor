# AWS Costs Advisor REST API

## Overview
AWS Costs Advisor provides a **REST API** that allows users to request AWS cost analysis via **Postman** or any HTTP client. The analysis is **generated using AWS Bedrock Gen AI**, providing insights into AWS spending.

## 📌 API Usage

### 🔹 **Endpoint**
```
POST https://<API_GATEWAY_URL>/costs-advisor
```

### 🔹 **Request Body**
```json
{
  "region": "us-east-1",
  "tag": "environment:production"
}
```

- **`region`**: (Required) AWS region to analyze costs. Default: `us-east-1`.
- **`tag`**: (Optional) Filter resources by a specific tag (e.g., `environment:production`). If omitted, analyzes all infrastructure in the selected region.

---

## **📌 Manual Configuration for AWS Bedrock**

To enable **AWS Bedrock** and ensure the system works correctly, follow these steps:

### **1️⃣ Enable AWS Bedrock in Your AWS Account**
1. Go to the **AWS Bedrock Console**: [AWS Bedrock](https://us-east-1.console.aws.amazon.com/bedrock/home)
2. Select the **region `us-east-1` (N. Virginia)`** (Bedrock is not available in all regions).
3. If prompted, **enable AWS Bedrock** in your account.

### **2️⃣ Enable Model Access for Anthropic Claude v2**
1. Inside the **AWS Bedrock Console**, go to **Model Access**.
2. Locate **Anthropic Claude v2**.
3. Click **Enable Access**.

### **3️⃣ Ensure IAM Permissions for AWS Bedrock**
If you're not using **Terraform**, manually add the following IAM policy to your Lambda execution role:
```json
{
  "Effect": "Allow",
  "Action": "bedrock:InvokeModel",
  "Resource": "*"
}
```

### **4️⃣ Test AWS Bedrock Access Manually** (Optional)
You can test AWS Bedrock via the AWS CLI:
```sh
aws bedrock-runtime invoke-model \
    --model-id anthropic.claude-v2 \
    --content-type "application/json" \
    --body '{ "prompt": "Analyze this AWS cost data: { \"cost\": 500 }", "max_tokens": 300 }'
```
If the command returns a response, AWS Bedrock is properly configured.

---

Now your AWS Bedrock configuration is complete, and the system is ready to process cost analysis requests! 🚀