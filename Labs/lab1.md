# **Lab 1: Real-Time Flight Booking Management Using Logic Apps and Service Bus**

#### **Objective**

In this lab, you will create a Logic App that processes flight booking data received via an API POST request. The Logic
App will filter confirmed bookings, compose relevant booking details, and send the information to a Service Bus topic.
You will also configure appropriate API responses based on the booking status.

#### **Prerequisites**

- Access to an Azure subscription.
- Deployment of a Service Bus namespace with an `inbound` topic.
- Visual Studio Code with
  the [REST Client extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client).

### **Step 1: Configure the Logic App for Receiving and Processing Booking Data (`logicApp`)**

1. **Create the Logic App Workflow**:
    - Log in to the [Azure Portal](https://portal.azure.com/).
    - Navigate to **Logic Apps** which has a name started with "ais-logicapp*" (e.g. `ais-logicapp-u44pedd3bligu`).
    - **Create a new Workflow**: Enter the name `booking`.
    - **Select Stateful**: Ensure that you select **Stateful** as the type for the workflow.
    - Click **Create**.

2. **Define the Request Schema**:

    - Add a trigger
    - Choose the trigger **When a HTTP request is received**.
    - Choose the method **POST**.
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

    - Click **Done** to generate the schema.

### **Step 2: Add a Condition to Filter Messages**

1. **Insert a Condition Step**:
    - Click on **+ New step**.
    - Search for **Condition** and select it.

2. **Configure the Condition**:
    - Under **Choose a value**, select `bookingStatus` from the dynamic content list.
    - Set the condition to **equals** and type `"confirmed"`.

3. **Handle the Condition Outcomes**:
    - **If true**: Add actions to handle confirmed bookings.
    - **If false**: Add actions to handle unconfirmed bookings.

### **Step 3: Compose Data for Confirmed Bookings**

1. **Add a Compose Action**:
    - Under the **If true** branch, click **+ Add an action**.
    - Search for **Compose** and select it.

2. **Define the Output of the Compose Action**:
    - In the **Inputs** field, paste the following JSON:

      ```json
      {
        "bookingId": "@{triggerBody()?['bookingId']}",
        "bookingStatus": "@{triggerBody()?['bookingStatus']}",
        "customerName": "@{triggerBody()?['customerName']}",
        "flightNumber": "@{triggerBody()?['flightNumber']}",
        "departureTime": "@{triggerBody()?['departureTime']}",
        "destination": "@{triggerBody()?['destination']}"
      }
      ```

### **Step 4: Send to Service Bus Topic**

1. **Add a Service Bus Action**:
    - Click on **+ Add an action** under the Compose action.
    - Create a new connection to the Service Bus to send message. Get the Connection String by following this step https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-servicebus?tabs=consumption#get-connection-string-for-service-bus-namespace
    - Connection String should be in the format `Endpoint=sb://<namespace>.servicebus.windows.net/;SharedAccessKeyName=<keyname>;SharedAccessKey=<key
    - Search for **Service Bus** and select **Send message to Service Bus Topic**.

2. **Configure the Service Bus Action**:
    - Select the Service Bus Namespace and Topic Name (`inbound`).
    - Select 'Content' from Advanced parameters
    - Choose "Outputs" from the Compose action as the message content.

### **Step 5: Add API Responses**

1. **Response for Confirmed Booking**:
    - Under the **If true** branch, click **+ Add an action**.
    - Search for **Response** and select it.
    - Set the **Status Code** to `200` (OK) and provide the following JSON response:

      ```json
      {
        "status": "Success",
        "message": "Booking confirmed and processed.",
        "bookingId": "@{triggerBody()?['bookingId']}",
        "customerName": "@{triggerBody()?['customerName']}",
        "flightNumber": "@{triggerBody()?['flightNumber']}"
      }
      ```

2. **Response for Unconfirmed Booking**:
    - Under the **If false** branch, click **+ Add an action**.
    - Search for **Response** and select it.
    - Set the **Status Code** to `200` (OK) or `400` (Bad Request) and provide the following JSON response:

      ```json
      {
        "status": "Ignored",
        "message": "Booking not confirmed. No action taken.",
        "bookingId": "@{triggerBody()?['bookingId']}",
        "customerName": "@{triggerBody()?['customerName']}"
      }
      ```

### **Step 6: Deploy and Test the Logic App**

1. **Save the Workflow**:
    - Click **Save** to apply the changes.

2. **Test the Workflow**:
    - Deploy the Logic App and obtain the HTTP POST URL from the Logic App designer.

### **Step 7: Test the Workflow Using HTTP Requests**

1. **Open HTTP Test File**:
    - Open file named [test.http](../test.http) in your Visual Studio Code workspace and paste the following test
      requests:

   ```http
   @baseUrl = https://<YOUR_LOGIC_APP_URL>
   ### Test Confirmed Booking
   POST {{baseUrl}}
   Content-Type: application/json

   {
     "bookingId": "12345",
     "customerName": "John Doe",
     "flightNumber": "SQ001",
     "bookingStatus": "confirmed",
     "departureTime": "2024-08-14T10:00:00Z",
     "destination": "Singapore"
   }

   ### Test Unconfirmed Booking
   POST {{baseUrl}}
   Content-Type: application/json

   {
     "bookingId": "12346",
     "customerName": "Jane Doe",
     "flightNumber": "SQ002",
     "bookingStatus": "pending",
     "departureTime": "2024-08-15T10:00:00Z",
     "destination": "Sydney"
   }
   ```

    - Replace `<YOUR_LOGIC_APP_URL>` with the actual URL of your `booking` Logic App.

2. **Send Test Requests**:
    - Use the REST Client extension in Visual Studio Code to send each POST request:
        - The first request tests a confirmed booking.
        - The second request tests an unconfirmed booking.

3. **Verify the Outcomes**:
    - **For Confirmed Booking**:
        - Ensure the data is sent to the Service Bus `inbound` topic.
        - Verify the API returns a `200 OK` status with the success message.

    - **For Unconfirmed Booking**:
        - Ensure the API returns a `400 Bad Request` status with the appropriate message.

### **Conclusion**

By completing this lab, you have created a Logic App that efficiently manages flight booking data. It processes bookings
based on their status, sends confirmed bookings to a Service Bus topic, and provides appropriate API responses. This
setup forms the foundation of a scalable, event-driven architecture for managing flight bookings.