# **Lab 4: Advanced Analytics with Azure Data Explorer & Business Process Monitoring in Azure Integration Environment**

#### **Objective**
In this lab, you will integrate Azure Data Explorer (ADX) for advanced analytics and leverage the Azure Integration Environment (AIE) for Business Process Monitoring (BPM) to track and monitor the entire workflow, from booking data processing to archiving and analytics.

#### **Prerequisites**
- Completion of Labs 1, 2, and 3.
- Azure Data Explorer (ADX) with the `businessprocesstracking` database already created.
- Azure Integration Environment (AIE) already deployed via Bicep.
- Basic understanding of Azure Data Explorer, AIE, and how to create and manage Kusto queries.

### **Step 1: Set Up Azure Data Explorer (ADX) for Business Process Tracking**

1. **Create a Table in ADX for Tracking Data**:
   - Navigate to the `businessprocesstracking` database within your Azure Data Explorer cluster.
   - Right-click on the database name and select **Create Table**.
   - **Define the Table Schema**:
     - **Table Name**: Enter a name (e.g., `BookingProcessTracking`).
     - **Columns**:
       - `Timestamp`: `datetime`
       - `ProcessName`: `string`
       - `BookingId`: `string`
       - `Status`: `string`
       - `Duration`: `timespan`
       - `ErrorDetails`: `string` (Optional, if you want to log error information)
   - Click **Create** to finalize the table creation.

2. **Set Up a Data Connection to Ingest Data from Cosmos DB**:
   - Navigate to the **Data connections** section under your `businessprocesstracking` database.
   - Click **+ Add data connection** and select **Cosmos DB** as the data source.
   - **Configure the Data Connection**:
     - **Data connection name**: Enter a name (e.g., `processed-data`).
     - **Subscription**: Select your Azure subscription.
     - **Cosmos DB account**: Choose your Cosmos DB account.
     - **SQL database**: Select the `processed-data` database.
     - **SQL container**: Choose the `bookings` container.
     - **Table name**: Enter the name of the table you created (e.g., `BookingProcessTracking`).
     - **Managed identity type**: Select **System-assigned**.
     - Click **Save** to create the data connection.
   - The system-assigned identity will automatically be granted the necessary permissions (e.g., `Azure Cosmos DB Reader` role).

3. **Run a Simple Kusto Query**:
   - Test the setup by running a simple Kusto query to ensure that the table is ready to receive data:
     ```kusto
     BookingProcessTracking
     | take 10
     ```
   - This should return the top 10 rows from the `BookingProcessTracking` table (if any data is present).

### **Step 2: Set Up Business Process Monitoring (BPM) in Azure Integration Environment (AIE)**

1. **Verify Azure Integration Environment (AIE)**:
   - Ensure your AIE is deployed and operational within your Azure subscription.
   - Navigate to your AIE resource in the Azure Portal.

2. **Set Up BPM Tracking**:
   - Within AIE, go to the **Monitoring** section.
   - **Create a New Process**:
     - Define a new BPM process for tracking the booking data workflow.
     - Set up tracking points for key stages, such as:
       - When a booking is received by the Logic App.
       - When data is archived into Cosmos DB.
       - When data is ingested into ADX.
   - **Define Monitoring Metrics**:
     - Set up metrics to track the number of bookings processed, the time taken for each step, and any errors or exceptions encountered.

3. **Enable Real-Time Alerts**:
   - Configure real-time alerts in AIE to notify you of any issues or performance bottlenecks in the workflow.
   - Set thresholds for alerts, such as a delay in data ingestion or an increase in failed bookings.

### **Step 3: Analyze Business Process Data with Kusto Queries in ADX**

1. **Create Kusto Queries for BPM**:
   - Use Kusto Query Language (KQL) to analyze the business process tracking data in ADX.
   - **Example Queries**:
     - Find all processes with a specific status (e.g., "Failed"):
       ```kusto
       BookingProcessTracking
       | where Status == "Failed"
       | project Timestamp, ProcessName, BookingId, ErrorDetails
       ```
     - Analyze the average duration of each process:
       ```kusto
       BookingProcessTracking
       | summarize avg(Duration) by ProcessName
       ```
     - Track the number of processes completed over time:
       ```kusto
       BookingProcessTracking
       | summarize ProcessCount = count() by bin(Timestamp, 1h), ProcessName
       | render timechart
       ```

2. **Create Dashboards in Azure Data Explorer**:
   - Use the **Dashboards** feature in ADX to create visualizations based on your Kusto queries.
   - Build dashboards to monitor the performance and status of your business processes, and track key metrics.

### **Step 4: Integrate AIE BPM with ADX for End-to-End Monitoring**

1. **Link BPM Data to ADX**:
   - If needed, export BPM data from AIE into ADX for detailed analysis.
   - Set up an ingestion pipeline in ADF or directly in ADX to bring BPM data into the `businessprocesstracking` table for analysis.

2. **Create Combined Dashboards**:
   - Use ADX to create combined dashboards that include both booking data and BPM metrics.
   - This allows you to monitor the entire process from data ingestion to archiving and analytics.

### **Summary**
In this lab, you have integrated Azure Data Explorer with your business process monitoring in Azure Integration Environment. You have:
- Created a table in Azure Data Explorer to store and analyze business process tracking data.
- Set up and configured business process monitoring in Azure Integration Environment.
- Built Kusto queries and dashboards to monitor and analyze the performance of your business processes.

This setup allows you to gain deep insights into the efficiency and reliability of your business workflows, providing a comprehensive view of your data processing and monitoring pipeline.

---

This updated guide now includes the step to create a data connection between your Cosmos DB and Azure Data Explorer, allowing you to ingest data directly into the `BookingProcessTracking` table for analysis and monitoring.