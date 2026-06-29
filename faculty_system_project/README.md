# Faculty Information Storage System
### Database Systems Lab | BSSE-A | Muhammad Gulsher & Muhammad Ali Bilal

---

## 📁 Project Structure

```
faculty_system/
│
├── app.py                  ← Main Flask application (run this)
├── setup_db.sql            ← MySQL schema + seed data (run ONCE)
├── requirements.txt        ← Python packages
│
└── templates/
    ├── base.html           ← Layout + sidebar + styles
    ├── login.html          ← Login page
    ├── dashboard.html      ← Dashboard with stats
    ├── faculty.html        ← Faculty list
    ├── faculty_form.html   ← Add/Edit faculty
    ├── faculty_view.html   ← Faculty detail profile
    ├── departments.html    ← Departments list
    ├── dept_form.html      ← Add/Edit department
    ├── qualifications.html ← Qualifications list
    ├── qual_form.html      ← Add/Edit qualification
    ├── workload.html       ← Workload list
    ├── workload_form.html  ← Add/Edit workload
    ├── users.html          ← Users list (admin only)
    └── user_form.html      ← Add user
```

---

## ⚙️ Setup Steps

### Step 1 — Install Python Packages
Open terminal in PyCharm and run:
```bash
pip install flask mysql-connector-python
```

### Step 2 — Set Up MySQL Database
Open MySQL Workbench (or any MySQL client) and run:
```
setup_db.sql
```
This will:
- Create the `faculty_info_system` database
- Create all 5 tables with constraints and indexes
- Insert sample departments, faculty, qualifications, workload
- Create the default admin user

### Step 3 — Configure DB Credentials in app.py
Open `app.py` and edit lines 22–28:
```python
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',       # ← Your MySQL username
    'password': '',       # ← Your MySQL password
    'database': 'faculty_info_system',
    'charset': 'utf8mb4'
}
```

### Step 4 — Run the App
In PyCharm, right-click `app.py` → Run  
OR in terminal:
```bash
python app.py
```

### Step 5 — Open in Browser
```
http://localhost:5000
```

---

## 🔐 Default Login

| Username | Password  | Role  |
|----------|-----------|-------|
| admin    | admin123  | Admin |

---

## ✅ Features

| Feature              | Admin | Faculty |
|----------------------|-------|---------|
| View Dashboard       | ✅    | ✅      |
| View Faculty List    | ✅    | ✅      |
| Add/Edit/Delete Faculty | ✅ | ❌      |
| View Departments     | ✅    | ✅      |
| Add/Edit Departments | ✅    | ❌      |
| View Qualifications  | ✅    | ✅      |
| Add/Edit Qualifications | ✅ | ❌      |
| View Workload        | ✅    | ✅      |
| Add/Edit Workload    | ✅    | ❌      |
| Manage Users         | ✅    | ❌      |
| Search & Filter      | ✅    | ✅      |

---

## 🗃️ Database Tables

- **department** — University departments
- **faculty** — Faculty member records  
- **qualifications** — Academic degrees per faculty  
- **workload** — Course assignments per semester  
- **users** — Authentication (admin + faculty portal)

---

## 🔧 Tech Stack

- **Backend:** Python 3 + Flask
- **Database:** MySQL 8 via mysql-connector-python
- **Frontend:** HTML5 + CSS3 (dark theme, no external frameworks)
- **Auth:** Session-based with SHA-256 password hashing
