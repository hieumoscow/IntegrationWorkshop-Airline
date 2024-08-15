# **Lab 2: Flight Booking Data Processing and Archiving with Cosmos DB and Blob Storage**

#### **Objective**
In this lab, you will extend the workflow from Lab 1 by using a Logic App (`otherlogicapp`) to process flight booking data sent to a Service Bus topic. The Logic App will store the processed booking data in Cosmos DB and archive the data as a file in Azure Blob Storage. Additionally, you'll expose this functionality via an API in Azure API Management (APIM) and enable logging via Application Insights.

#### **Prerequisites**
- Completion of Lab 1.
- Access to an Azure subscription.
- Deployment of a Service Bus namespace with an `inbound` topic.
- Deployment of Cosmos DB with a `processed-data` database and a `bookings` container.
- Deployment of Azure Blob Storage with a container (e.g., `inbound-data`).
- Deployment of a Logic App (`otherlogicapp`) to process the booking data.
- Setup of Application Insights.

### **Step 1: Create a Service Bus Topic Subscription "BookingProcessorSub"**

1. **Navigate to the Service Bus Namespace**:
   - Log in to the [Azure Portal](https://portal.azure.com/).
   - Navigate to **Service Bus** and select the namespace you used in Lab 1.

2. **Select the `inbound` Topic**:
   - Under the **Entities** section, select **Topics** and then choose the `inbound` topic.

3. **Create a New Subscription**:
   - Click on **+ Subscription** to create a new subscription for the `inbound` topic.
   - **Name the Subscription**: Enter `BookingProcessorSub` as the subscription name.
   - **Subscription Settings**:
     - Leave the default settings for **Max delivery count**, **Time to live**, and other settings unless specific adjustments are needed for your scenario.
   - Click **Create** to create the subscription.

4. **Verify the Subscription**:
   - Once the subscription is created, ensure that `BookingProcessorSub` appears under the **Subscriptions** section for the `inbound` topic.

### **Step 2: Configure the `otherlogicapp` to Process and Store Booking Data**

1. **Create the Logic App Workflow**:
   - Log in to the [Azure Portal](https://portal.azure.com/).
   - Navigate to **Logic Apps** and create a new Logic App named `otherlogicapp`.
   - **Select Stateful**: Ensure that you select **Stateful** as the type for the workflow.
   - Click **Review + Create** and then **Create**.

2. **Design the Workflow**:

   **a. Trigger the Logic App**:
   - **Trigger**: Use the trigger **When a message is received in a topic subscription (auto-complete)**.
   - **Subscription**: Set this trigger to listen to the `BookingProcessorSub` subscription in the `inbound` topic of the Service Bus.
   
   **b. Parse the JSON**:
   - Add a **Parse JSON** action to decode the message content and ensure it's in the correct format.
   - **Content**: Use the following expression to decode the message content:
     ```json
     @decodeBase64(triggerBody()?['ContentData'])
     ```
   - **Generate Schema**: 
     - Click on **Use sample payload to generate schema**.
     - Paste the following JSON as a sample request payload:
       ```json
       {
         "bookingId": "12345",
         "customerName": "John Doe",
         "flightNumber": "SQ001",
         "bookingStatus": "confirmed",
         "departureTime": "2024-08-14T10:00:00Z",
         "destination": "Singapore"
       }
       ```
     - Click **Done** to generate the schema. This schema will automatically define the structure for the parsed JSON content.

   **c. Condition to Check Booking Status**:
   - Add a **Condition** action to check if the `bookingStatus` is `"confirmed"`.
   - **If True**:
     - **Store Data in Cosmos DB**:
       - Use the `Create or Update Item` action to insert the processed booking data into Cosmos DB.
       - Use the following JSON for the `item`:
         ```json
         {
           "id": "@{concat(body('Parse_JSON')?['customerName'], '-', body('Parse_JSON')?['flightNumber'], '-', body('Parse_JSON')?['departureTime'])}",
           "bookingId": @{body('Parse_JSON')?['bookingId']},
           "customerName": "@{body('Parse_JSON')?['customerName']}",
           "flightNumber": "@{body('Parse_JSON')?['flightNumber']}",
           "departureTime": "@{body('Parse_JSON')?['departureTime']}",
           "destination": "@{body('Parse_JSON')?['destination']}"
         }
         ```
     - **Archive Data to Blob Storage**:
       - Use the `Create blob (V2)` action to save the JSON data as a file in Azure Blob Storage. 
       - Use the following JSON for the content:
         ```json
         {
           "id": "@{concat(body('Parse_JSON')?['customerName'], '-', body('Parse_JSON')?['flightNumber'], '-', body('Parse_JSON')?['departureTime'])}",
           "bookingId": "@{body('Parse_JSON')?['bookingId']}",
           "customerName": "@{body('Parse_JSON')?['customerName']}",
           "flightNumber": "@{body('Parse_JSON')?['flightNumber']}",
           "departureTime": "@{body('Parse_JSON')?['departureTime']}",
           "destination": "@{body('Parse_JSON')?['destination']}"
         }
         ```
       - **Blob Name**: Create a unique name for the blob using the booking ID:
         ```text
         @{concat('booking-', body('Parse_JSON')?['bookingId'], '.json')}
         ```

   **d. Run the Workflow**:
   - Save and deploy the `otherlogicapp`.
   - Test it by sending a booking message from the `booking` Logic App (from Lab 1) and ensuring it is processed correctly by `otherlogicapp`.

### **Step 3: Create and Configure an API in Azure API Management**

1. **Create the API in Azure API Management**:
   - Log in to the [Azure Portal](https://portal.azure.com/).
   - Navigate to **API Management services** and select your APIM instance (`apimv2`).
   - In the **APIs** section, click **+ Add API** and select **Blank API**.
   - **Configure the API**:
     - **Display Name**: Enter `Booking`.
     - **Name**: Enter `booking`.
     - **URL**: Enter the base URL of your Logic App endpoint up to `/api`. For example:
       ```text
       https://<logicapp-name>.azurewebsites.net/api
       ```
     - **API URL suffix**: Enter `booking`.
     - **Description**: Optionally, provide a description for your API.
   - Click **Create**.

2. **Add an Operation to the API**:
   - After the API is created, you will need to define the operations (endpoints).
   - Click on **+ Add Operation**.
   - **Display Name**: Name the operation (e.g., `Booking`).
   - **Method**: Select `POST` as the HTTP method.
   - **URL template**: Set the path as `/booking`.
   - Click **Save**.

3. **Set Up the Rewrite URL Policy**:
   - In the **Design** tab, select the **Frontend** section.
   - Click on **Inbound processing** and add the following rewrite URL policy:
     ```xml
     <inbound>
         <base />
         <rewrite-uri template="/Booking/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&amp;sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&amp;sv=1.0&amp;sig=HG-4eqU__B084DqD10168HIoEAZ59YAViO2gv2P4QaU" copy-unmatched-params="true" />
     </inbound>
     ```
   - This policy rewrites the incoming request URL to the correct Logic App trigger URL.

4. **Configure Application Insights for API Diagnostics Logs**:
   - Navigate to the **Settings** tab of your API in APIM.
   - Under **Diagnostics Logs**, enable **Application Insights**.
   - Set the **Destination** to the Application Insights resource (`appins`) you have configured.
   - Ensure **Sampling** is set to 100% (or adjust based on your traffic).
   - Save these settings to ensure that all API traffic is logged in Application Insights for monitoring and diagnostics.

5. **Test the API**:
   - Navigate to the **Test** tab in API Management.
   - Send a POST request to the `/booking` endpoint and verify that it correctly triggers the Logic App.

### **Step 4: Create a Starter Product Without Subscription**

1. **Create a New Product**:
   - In the **API Management services** section, navigate to **Products** and click **+ Add product**.
   - **Name**: Give your product a name (e.g., `Starter`).
   - **Description**: Optionally, provide a description.
   - **Require subscription**: Disable this option to allow access without requiring a subscription.
   - **APIs**: Attach the `Booking` API to this product.
   - **Publish the product** to make it available.

2. **Test the API Externally**:
   - Use an external tool like Postman or cURL to send requests to the API endpoint and ensure that everything works as expected, including the API being accessible without a subscription.

### **Final Verification and Monitoring**

1. **Monitor API Usage**:
   - Use the **Analytics** section in APIM to monitor the usage, performance, and health of your API.
   - This will help you track how the API is being used, how often, and by whom, which is essential for maintaining and scaling the service.

2. **Review Logs in Application Insights**:
   - Go to your Application Insights resource (`appins`) in the Azure Portal.
   - Navigate to the **Logs** section and query the logs to see the requests, responses, and any errors or performance issues.
   - This logging will help you diagnose issues, monitor API performance, and understand user behavior.

3. **Security Considerations**:
   - Although the starter product does not require a subscription, consider applying rate limiting or other security measures if the API will be publicly accessible.
   - Review the security policies and ensure that the API is protected against unauthorized access and potential misuse.

4. **Performance Tuning**:
   - If you find that the API is being heavily used or that there are performance issues, consider scaling the APIM instance or optimizing the Logic Apps, Cosmos DB, and Blob Storage workflows.
   - You can also configure caching, compression, and other performance-related policies within APIM to improve response times.

### **Summary**
By completing this lab, you have successfully created a robust flight booking processing pipeline. This includes:
- Setting up a Service Bus topic and subscription for message processing.
- Configuring a Logic App (`otherlogicapp`) to process booking messages, store them in Cosmos DB, and archive them in Blob Storage.
- Exposing the Logic App via a user-friendly API endpoint in Azure API Management.
- Enabling Application Insights diagnostics to monitor and troubleshoot the API.
- Creating a starter product in APIM that does not require a subscription, making the API easily accessible.

This setup not only allows you to process and store flight booking data but also provides a scalable and secure API that can be consumed by external clients or integrated into larger systems.

### **Next Steps**
In the next lab (Lab 3), you will further enhance this setup by integrating Azure Data Factory (ADF) to process and analyze the archived booking data in Blob Storage. This will allow for more advanced data processing and reporting capabilities.
