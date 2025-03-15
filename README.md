# E-Commerce Data Analysis

### Introduction
In this project we use the dataset provided by Instacart and upload it to Postgresql Database through Python Script for further Analysis

### About Dataset
This dataset contains products and their information as provided by [Instacart](https://www.kaggle.com/competitions/instacart-market-basket-analysis/data)

### Tools and Technologies

* Python
* Jupyter Notebook
* Postgresql
* pgAdmin for Database Mangement
* app.diagrams.net to create Design Model

### Project Execution

* Create a Python Script through Jupyter to implement:
    + Import dataset into dataframes using Pandas
    + Establish connection with database
    + Create tables
    + Insert data
* Database Analysis :
    + Validate Data
    + Create Views for Analysis
    + Create function for end user access and output CSV generation

### Python Packages used
```
import pandas
import psycopg2
from sqlalchemy import create_engine
```

### Data Model
![Data Model Diagram](https://github.com/swethagopisetty/E-comm_Data_Analysis_Python_SQL/blob/main/Data_Model.png)
