# **Lab 3: Advanced Data Processing with Azure Data Factory (ADF)**

#### **Objective**
In this lab, you will build on the setup from Labs 1 and 2 by using the already deployed Azure Data Factory (ADF) to process, transform, and analyze the archived booking data stored in Azure Blob Storage. The goal is to automate data processing tasks such as extracting, transforming, and loading (ETL) the data into Cosmos DB for reporting and analytics purposes, including archiving processed data.

#### **Prerequisites**
- Completion of Labs 1 and 2.
- ADF deployed and configured via Bicep with linked services to Cosmos DB and Blob Storage (`inbound-data` container).
- Archived booking data stored in Azure Blob Storage (`inbound-data` container).
- Basic understanding of Azure Data Factory, including creating pipelines and datasets.

### **Step 1: Verify the Linked Services in ADF**

1. **Open Azure Data Factory Studio**:
   - Log in to the [Azure Portal](https://portal.azure.com/).
   - Navigate to **Azure Data Factory** and select your deployed ADF instance.
   - Click on **Author & Monitor** to open ADF Studio.

2. **Verify Linked Services**:
   - In ADF Studio, go to the **Manage** tab (gear icon on the left).
   - Under **Connections**, select **Linked services**.
   - Ensure that the linked services for **Azure Blob Storage** (pointing to the `inbound` container) and **Azure Cosmos DB** are correctly configured.

### **Step 2: Create a New Container in Cosmos DB for Archiving**

1. **Navigate to Your Cosmos DB Account**:
   - In the Azure Portal, go to your Cosmos DB account that was configured earlier.

2. **Add a New Container**:
   - Under your `processed-data` database, click on **+ Add Container**.
   - **Container ID**: Enter a name for your new container (e.g., `archive`).
   - **Partition Key**: Set the partition key (e.g., `/bookingId`).
   - **Throughput**: You can configure the throughput as required (e.g., set it to the default value or customize it based on your expected load).
   - Click **OK** to create the container.

3. **Verify the Container**:
   - Ensure the new `archive` container is visible under your `processed-data` database.

### **Step 3: Create Datasets**

1. **Create a Dataset for Blob Storage**:
   - Go to the **Author** tab (pencil icon) and select **Datasets**.
   - Click **+ New** to create a new dataset.
   - **Select Azure Blob Storage** as the data source.
   - **Configure the Dataset**:
     - **Name**: Enter a name (e.g., `BlobStorageDataset`).
     - **Linked Service**: Select the linked service for Azure Blob Storage you verified earlier.
     - **File Path**: Set the file path to the location of the JSON files in the `inbound` container.
     - **File format**: Select **JSON** as the file format.
     - Click **OK** to create the dataset.

2. **Create a Dataset for Cosmos DB (Archived Data)**:
   - Repeat the above steps to create a dataset for the new `archive` container in Cosmos DB.
   - **Select Azure Cosmos DB** as the data source.
   - **Configure the Dataset**:
     - **Name**: Enter a name (e.g., `CosmosDBArchiveDataset`).
     - **Linked Service**: Select the linked service for Cosmos DB.
     - **Collection Name**: Select the `archive` container within the `processed-data` database.
     - Click **OK** to create the dataset.

### **Step 4: Create an ETL Pipeline**

1. **Create a New Pipeline**:
   - In the **Author** tab, select **Pipelines** and click **+ New** to create a new pipeline.
   - **Name**: Enter a name for your pipeline (e.g., `BookingDataPipeline`).

2. **Add a Copy Data Activity for Archiving Data**:
   - From the **Activities** pane, drag a **Copy Data** activity onto the pipeline canvas.
   - **Source**:
     - Select the **Source** tab in the activity's settings.
     - **Dataset**: Choose the `BlobStorageDataset` you created earlier.
     - **File Path**: Use the **Wildcard file path** option to define the path to the JSON files. 
       - **Wildcard paths**: Set it to process all JSON files in the `inbound-data` container with a pattern like `*/ *.json`.
       - Enable the **Recursively** option if you want to process files in subfolders as well.
   - **Sink**:
     - Select the **Sink** tab.
     - **Dataset**: Choose the `CosmosDBArchiveDataset`.
     - **Write behavior**: Set the write behavior to **Insert** to archive the data without overwriting any existing records.

3. **Configure the Pipeline Trigger**:
   - Click on the **Trigger** button (with the clock icon) on the top of the pipeline canvas.
   - Click **+ New** to create a new trigger.
   - **Trigger Type**: Set the trigger type to **Schedule**.
   - **Schedule**: Define the schedule (e.g., daily) for running the pipeline.
   - Click **OK** to create the trigger.

4. **Validate and Publish the Pipeline**:
   - Click **Validate** to ensure there are no errors in the pipeline.
   - Once validated, click **Publish All** to deploy the pipeline.

### **Step 5: Monitor the Pipeline**

1. **Monitor Pipeline Runs**:
   - Go to the **Monitor** tab in Data Factory Studio.
   - Track the status of pipeline runs, view logs, and diagnose any issues.

2. **Review Data in Cosmos DB**:
   - Navigate to your Cosmos DB account in the Azure Portal.
   - Verify that the booking data has been successfully loaded into the `archive` container.

3. **Analyze Data with Power BI (Optional)**:
   - Connect Power BI to your Cosmos DB or Blob Storage to visualize and analyze the archived booking data.
   - Create reports and dashboards to gain insights into flight bookings.

### **Summary**
In this lab, you have successfully leveraged the Azure Data Factory deployment from your Bicep template to process and archive booking data stored in Blob Storage. You have:
- Verified the linked services in ADF.
- Created datasets to define the data sources and sinks.
- Built an ETL pipeline to extract, transform, and load booking data from Blob Storage to an archive container in Cosmos DB.
- Scheduled and monitored the pipeline to automate the data processing workflow.

This setup enables you to efficiently process and archive large volumes of booking data, providing a foundation for advanced analytics and reporting using tools like Power BI.
