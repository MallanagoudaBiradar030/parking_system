# parking_system
# 🚗 PARKEASE – Parking Lot Database Management System

PARKEASE is a full-stack Parking Lot Database Management System developed as a DBMS mini project using Flask and MySQL.  
The system helps parking operators manage vehicle entries, exits, slot allocation, parking history, and revenue tracking through a modern dashboard interface.

---

# 📌 Project Overview

Managing parking lots manually becomes difficult when handling multiple vehicles, slot tracking, billing, and availability management.  
PARKEASE automates the complete parking management workflow using database-driven operations.

The project demonstrates practical implementation of:

- Database Management Systems
- SQL Queries
- Views
- Triggers
- Stored Procedures
- Flask Backend Development
- Frontend Dashboard UI

---

# ✨ Features

## 🔐 Authentication System
- Secure operator login
- Session-based authentication
- Protected routes using Flask login management

## 🚘 Vehicle Entry Management
- Register incoming vehicles
- Assign parking slots automatically
- Store entry timestamps

## 🚪 Vehicle Exit System
- Calculate parking duration
- Generate parking fees
- Update slot availability automatically

## 🅿️ Parking Slot Management
- Live slot occupancy tracking
- Separate slots for different vehicle types
- Real-time available slot monitoring

## 📊 Dashboard Analytics
- Occupied parking spaces
- Available slots
- Revenue tracking
- Recent parking activity logs

## 📄 Database Features
- SQL Views
- Triggers
- Stored Procedures
- Aggregate queries
- INNER JOIN operations

---

# 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Python | Backend Programming |
| Flask | Web Framework |
| MySQL | Database |
| HTML5 | Structure |
| CSS3 | Styling |
| JavaScript | Frontend Interaction |
| Jinja2 | Dynamic Templates |

---

# 🗂️ Project Structure

```text
parking_system/
│
├── app.py
├── db.py
├── requirements.txt
├── README.md
│
├── templates/
│   ├── base.html
│   ├── login.html
│   ├── dashboard.html
│   ├── entry.html
│   ├── exit.html
│   └── parked.html
│
├── static/
│   ├── css/
│   ├── js/
│   └── images/
│
├── sql/
│   ├── schema.sql
│   ├── triggers.sql
│   ├── procedures.sql
│   └── seed.sql
│
└── venv/


🧠 Database Concepts Implemented
✅ Tables
user
vehicle
parking_slot
parking_transaction
✅ Views
vw_currently_parked
vw_monthly_revenue_summary
vw_slot_utilization
✅ Triggers
Automatic slot status updates
Entry/Exit automation
✅ Stored Procedures
Vehicle parking procedures
Exit handling procedures
✅ SQL Operations
INNER JOIN
GROUP BY
Aggregate Functions
CASE Statements
Transactions
⚙️ Installation Guide
1️⃣ Clone Repository
git clone https://github.com/YOUR_USERNAME/parking_system.git
2️⃣ Enter Project Directory
cd parking_system
3️⃣ Create Virtual Environment
python3 -m venv venv
4️⃣ Activate Virtual Environment
Linux / Ubuntu
source venv/bin/activate
5️⃣ Install Dependencies
pip install -r requirements.txt
6️⃣ Configure MySQL

Update database credentials inside db.py

host="localhost"
user="root"
password="YOUR_PASSWORD"
database="parking_db"
7️⃣ Run Application
python3 app.py
🌐 Application Access

Open browser:

http://127.0.0.1:5000

🔑 Default Login Credentials
Username: admin
Password: admin123

📸 Screens Included
Login Page
Dashboard
Vehicle Entry Form
Vehicle Exit Form
Parked Vehicles Roster
Revenue Report

📈 Dashboard Features
Total occupied spaces
Available slots
Current parked vehicles
Revenue statistics
Activity logs

🔥 Key Highlights
Modern dark-themed UI
Real-time parking updates
Fully database-driven system
Responsive layout
Practical DBMS implementation

🚀 Future Enhancements
QR code parking tickets
Online payment gateway
Mobile application support
Admin analytics dashboard
License plate recognition using AI
Email/SMS notifications

👨‍💻 Developed By

Mallanagouda S Biradar
Yashwanth R K
Varsha

Engineering Mini Project – Database Management System