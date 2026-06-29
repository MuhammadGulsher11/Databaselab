"""
Faculty Information Storage System
===================================
Flask + MySQL Web Application
Run: python app.py
Then open: http://localhost:5000
"""

from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import mysql.connector
from mysql.connector import Error
from functools import wraps
import hashlib
import os

app = Flask(__name__)
app.secret_key = 'faculty_system_secret_2025'

# ─── Database Configuration ────────────────────────────────────────────────
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',        # ← Change to your MySQL username
    'password': '12345678',        # ← Change to your MySQL password
    'database': 'faculty_info_system',
    'charset': 'utf8mb4'
}

def get_db():
    """Get a database connection."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        return None

def hash_password(password):
    """Simple SHA-256 hash for demo purposes."""
    return hashlib.sha256(password.encode()).hexdigest()

# ─── Auth Decorator ────────────────────────────────────────────────────────
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in first.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in first.', 'warning')
            return redirect(url_for('login'))
        if session.get('role') != 'admin':
            flash('Admin access required.', 'danger')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated

# ─── Routes ───────────────────────────────────────────────────────────────

@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

# ── Authentication ──────────────────────────────────────────────────────────

@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '').strip()
        if not username or not password:
            flash('Both fields are required.', 'danger')
            return render_template('login.html')
        conn = get_db()
        if not conn:
            flash('Database connection failed. Check your DB settings.', 'danger')
            return render_template('login.html')
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT * FROM users WHERE username = %s", (username,))
            user = cur.fetchone()
            hashed = hash_password(password)
            if user and user['user_password'] == hashed:
                session['user_id']    = user['user_id']
                session['username']   = user['username']
                session['role']       = user['role']
                session['faculty_id'] = user['faculty_id']
                cur.execute("UPDATE users SET last_login = NOW() WHERE user_id = %s", (user['user_id'],))
                conn.commit()
                flash(f"Welcome back, {username}!", 'success')
                return redirect(url_for('dashboard'))
            else:
                flash('Invalid username or password.', 'danger')
        finally:
            conn.close()
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully.', 'info')
    return redirect(url_for('login'))

# ── Dashboard ───────────────────────────────────────────────────────────────

@app.route('/dashboard')
@login_required
def dashboard():
    conn = get_db()
    stats = {'faculty': 0, 'departments': 0, 'qualifications': 0, 'workload': 0}
    recent_faculty = []
    dept_counts = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT COUNT(*) AS cnt FROM faculty")
            stats['faculty'] = cur.fetchone()['cnt']
            cur.execute("SELECT COUNT(*) AS cnt FROM department")
            stats['departments'] = cur.fetchone()['cnt']
            cur.execute("SELECT COUNT(*) AS cnt FROM qualifications")
            stats['qualifications'] = cur.fetchone()['cnt']
            cur.execute("SELECT COUNT(*) AS cnt FROM workload")
            stats['workload'] = cur.fetchone()['cnt']
            cur.execute("""
                SELECT f.faculty_id, f.name, f.email, f.gender, d.dept_name
                FROM faculty f JOIN department d ON f.dept_id = d.dept_id
                ORDER BY f.created_at DESC LIMIT 5
            """)
            recent_faculty = cur.fetchall()
            cur.execute("""
                SELECT d.dept_name, COUNT(f.faculty_id) AS total
                FROM department d LEFT JOIN faculty f ON d.dept_id = f.dept_id
                GROUP BY d.dept_id, d.dept_name
                ORDER BY total DESC LIMIT 6
            """)
            dept_counts = cur.fetchall()
        finally:
            conn.close()
    return render_template('dashboard.html', stats=stats,
                           recent_faculty=recent_faculty, dept_counts=dept_counts)

# ── Faculty CRUD ─────────────────────────────────────────────────────────────

@app.route('/faculty')
@login_required
def faculty_list():
    conn = get_db()
    faculty = []
    departments = []
    search = request.args.get('search', '')
    dept_filter = request.args.get('dept', '')
    gender_filter = request.args.get('gender', '')
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            query = """
                SELECT f.faculty_id, f.name, f.email, f.phone, f.gender,
                       f.cnic, f.date_of_birth, f.created_at, d.dept_name, d.dept_id
                FROM faculty f JOIN department d ON f.dept_id = d.dept_id
                WHERE 1=1
            """
            params = []
            if search:
                query += " AND (f.name LIKE %s OR f.email LIKE %s OR f.cnic LIKE %s)"
                params += [f'%{search}%', f'%{search}%', f'%{search}%']
            if dept_filter:
                query += " AND f.dept_id = %s"
                params.append(dept_filter)
            if gender_filter:
                query += " AND f.gender = %s"
                params.append(gender_filter)
            query += " ORDER BY f.faculty_id"
            cur.execute(query, params)
            faculty = cur.fetchall()
            cur.execute("SELECT dept_id, dept_name FROM department ORDER BY dept_name")
            departments = cur.fetchall()
        finally:
            conn.close()
    return render_template('faculty.html', faculty=faculty, departments=departments,
                           search=search, dept_filter=dept_filter, gender_filter=gender_filter)

@app.route('/faculty/add', methods=['GET', 'POST'])
@admin_required
def faculty_add():
    conn = get_db()
    departments = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT dept_id, dept_name FROM department ORDER BY dept_name")
            departments = cur.fetchall()
        finally:
            conn.close()
    if request.method == 'POST':
        data = {
            'name': request.form.get('name', '').strip(),
            'email': request.form.get('email', '').strip(),
            'phone': request.form.get('phone', '').strip() or None,
            'cnic': request.form.get('cnic', '').strip(),
            'gender': request.form.get('gender'),
            'dob': request.form.get('dob') or None,
            'dept_id': request.form.get('dept_id'),
        }
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO faculty (name, email, phone, cnic, gender, date_of_birth, dept_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, (data['name'], data['email'], data['phone'],
                      data['cnic'], data['gender'], data['dob'], data['dept_id']))
                conn.commit()
                flash('Faculty member added successfully!', 'success')
                return redirect(url_for('faculty_list'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('faculty_form.html', departments=departments, action='Add', faculty=None)

@app.route('/faculty/edit/<int:fid>', methods=['GET', 'POST'])
@admin_required
def faculty_edit(fid):
    conn = get_db()
    faculty = None
    departments = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT * FROM faculty WHERE faculty_id = %s", (fid,))
            faculty = cur.fetchone()
            cur.execute("SELECT dept_id, dept_name FROM department ORDER BY dept_name")
            departments = cur.fetchall()
        finally:
            conn.close()
    if not faculty:
        flash('Faculty not found.', 'danger')
        return redirect(url_for('faculty_list'))
    if request.method == 'POST':
        data = {
            'name': request.form.get('name', '').strip(),
            'email': request.form.get('email', '').strip(),
            'phone': request.form.get('phone', '').strip() or None,
            'cnic': request.form.get('cnic', '').strip(),
            'gender': request.form.get('gender'),
            'dob': request.form.get('dob') or None,
            'dept_id': request.form.get('dept_id'),
        }
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE faculty SET name=%s, email=%s, phone=%s, cnic=%s,
                    gender=%s, date_of_birth=%s, dept_id=%s WHERE faculty_id=%s
                """, (data['name'], data['email'], data['phone'],
                      data['cnic'], data['gender'], data['dob'], data['dept_id'], fid))
                conn.commit()
                flash('Faculty updated successfully!', 'success')
                return redirect(url_for('faculty_list'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('faculty_form.html', departments=departments, action='Edit', faculty=faculty)

@app.route('/faculty/delete/<int:fid>', methods=['POST'])
@admin_required
def faculty_delete(fid):
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("DELETE FROM faculty WHERE faculty_id = %s", (fid,))
            conn.commit()
            flash('Faculty member deleted.', 'success')
        except Error as e:
            flash(f'Cannot delete: {str(e)}', 'danger')
        finally:
            conn.close()
    return redirect(url_for('faculty_list'))

@app.route('/faculty/view/<int:fid>')
@login_required
def faculty_view(fid):
    conn = get_db()
    faculty = None
    qualifications = []
    workload = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("""
                SELECT f.*, d.dept_name FROM faculty f
                JOIN department d ON f.dept_id = d.dept_id
                WHERE f.faculty_id = %s
            """, (fid,))
            faculty = cur.fetchone()
            cur.execute("SELECT * FROM qualifications WHERE faculty_id = %s ORDER BY year_completed DESC", (fid,))
            qualifications = cur.fetchall()
            cur.execute("SELECT * FROM workload WHERE faculty_id = %s ORDER BY semester", (fid,))
            workload = cur.fetchall()
        finally:
            conn.close()
    if not faculty:
        flash('Faculty not found.', 'danger')
        return redirect(url_for('faculty_list'))
    return render_template('faculty_view.html', faculty=faculty,
                           qualifications=qualifications, workload=workload)

# ── Departments CRUD ──────────────────────────────────────────────────────────

@app.route('/departments')
@login_required
def departments():
    conn = get_db()
    depts = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("""
                SELECT d.*, COUNT(f.faculty_id) AS faculty_count
                FROM department d LEFT JOIN faculty f ON d.dept_id = f.dept_id
                GROUP BY d.dept_id ORDER BY d.dept_name
            """)
            depts = cur.fetchall()
        finally:
            conn.close()
    return render_template('departments.html', departments=depts)

@app.route('/departments/add', methods=['GET', 'POST'])
@admin_required
def dept_add():
    if request.method == 'POST':
        name = request.form.get('dept_name', '').strip()
        hod  = request.form.get('hod_name', '').strip() or None
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("INSERT INTO department (dept_name, hod_name) VALUES (%s, %s)", (name, hod))
                conn.commit()
                flash('Department added!', 'success')
                return redirect(url_for('departments'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('dept_form.html', action='Add', dept=None)

@app.route('/departments/edit/<int:did>', methods=['GET', 'POST'])
@admin_required
def dept_edit(did):
    conn = get_db()
    dept = None
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT * FROM department WHERE dept_id = %s", (did,))
            dept = cur.fetchone()
        finally:
            conn.close()
    if not dept:
        flash('Department not found.', 'danger')
        return redirect(url_for('departments'))
    if request.method == 'POST':
        name = request.form.get('dept_name', '').strip()
        hod  = request.form.get('hod_name', '').strip() or None
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("UPDATE department SET dept_name=%s, hod_name=%s WHERE dept_id=%s", (name, hod, did))
                conn.commit()
                flash('Department updated!', 'success')
                return redirect(url_for('departments'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('dept_form.html', action='Edit', dept=dept)

@app.route('/departments/delete/<int:did>', methods=['POST'])
@admin_required
def dept_delete(did):
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("DELETE FROM department WHERE dept_id = %s", (did,))
            conn.commit()
            flash('Department deleted.', 'success')
        except Error as e:
            flash(f'Cannot delete: {str(e)}', 'danger')
        finally:
            conn.close()
    return redirect(url_for('departments'))

# ── Qualifications CRUD ───────────────────────────────────────────────────────

@app.route('/qualifications')
@login_required
def qualifications():
    conn = get_db()
    quals = []
    search = request.args.get('search', '')
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            query = """
                SELECT q.*, f.name AS faculty_name
                FROM qualifications q JOIN faculty f ON q.faculty_id = f.faculty_id
                WHERE 1=1
            """
            params = []
            if search:
                query += " AND (f.name LIKE %s OR q.degree LIKE %s OR q.institution LIKE %s)"
                params = [f'%{search}%', f'%{search}%', f'%{search}%']
            query += " ORDER BY f.name, q.year_completed DESC"
            cur.execute(query, params)
            quals = cur.fetchall()
        finally:
            conn.close()
    return render_template('qualifications.html', qualifications=quals, search=search)

@app.route('/qualifications/add', methods=['GET', 'POST'])
@admin_required
def qual_add():
    conn = get_db()
    faculty_list = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT faculty_id, name FROM faculty ORDER BY name")
            faculty_list = cur.fetchall()
        finally:
            conn.close()
    if request.method == 'POST':
        fid    = request.form.get('faculty_id')
        degree = request.form.get('degree', '').strip()
        inst   = request.form.get('institution', '').strip()
        year   = request.form.get('year_completed') or None
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO qualifications (faculty_id, degree, institution, year_completed)
                    VALUES (%s, %s, %s, %s)
                """, (fid, degree, inst, year))
                conn.commit()
                flash('Qualification added!', 'success')
                return redirect(url_for('qualifications'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('qual_form.html', action='Add', qual=None, faculty_list=faculty_list)

@app.route('/qualifications/edit/<int:qid>', methods=['GET', 'POST'])
@admin_required
def qual_edit(qid):
    conn = get_db()
    qual = None
    faculty_list = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT * FROM qualifications WHERE qual_id = %s", (qid,))
            qual = cur.fetchone()
            cur.execute("SELECT faculty_id, name FROM faculty ORDER BY name")
            faculty_list = cur.fetchall()
        finally:
            conn.close()
    if not qual:
        flash('Qualification not found.', 'danger')
        return redirect(url_for('qualifications'))
    if request.method == 'POST':
        fid    = request.form.get('faculty_id')
        degree = request.form.get('degree', '').strip()
        inst   = request.form.get('institution', '').strip()
        year   = request.form.get('year_completed') or None
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE qualifications SET faculty_id=%s, degree=%s, institution=%s,
                    year_completed=%s WHERE qual_id=%s
                """, (fid, degree, inst, year, qid))
                conn.commit()
                flash('Qualification updated!', 'success')
                return redirect(url_for('qualifications'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('qual_form.html', action='Edit', qual=qual, faculty_list=faculty_list)

@app.route('/qualifications/delete/<int:qid>', methods=['POST'])
@admin_required
def qual_delete(qid):
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("DELETE FROM qualifications WHERE qual_id = %s", (qid,))
            conn.commit()
            flash('Qualification deleted.', 'success')
        except Error as e:
            flash(f'Error: {str(e)}', 'danger')
        finally:
            conn.close()
    return redirect(url_for('qualifications'))

# ── Workload CRUD ─────────────────────────────────────────────────────────────

@app.route('/workload')
@login_required
def workload():
    conn = get_db()
    workloads = []
    search = request.args.get('search', '')
    semester_filter = request.args.get('semester', '')
    semesters = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT DISTINCT semester FROM workload ORDER BY semester")
            semesters = [r['semester'] for r in cur.fetchall()]
            query = """
                SELECT w.*, f.name AS faculty_name
                FROM workload w JOIN faculty f ON w.faculty_id = f.faculty_id
                WHERE 1=1
            """
            params = []
            if search:
                query += " AND (f.name LIKE %s OR w.course_name LIKE %s)"
                params += [f'%{search}%', f'%{search}%']
            if semester_filter:
                query += " AND w.semester = %s"
                params.append(semester_filter)
            query += " ORDER BY f.name, w.semester"
            cur.execute(query, params)
            workloads = cur.fetchall()
        finally:
            conn.close()
    return render_template('workload.html', workloads=workloads, search=search,
                           semesters=semesters, semester_filter=semester_filter)

@app.route('/workload/add', methods=['GET', 'POST'])
@admin_required
def workload_add():
    conn = get_db()
    faculty_list = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT faculty_id, name FROM faculty ORDER BY name")
            faculty_list = cur.fetchall()
        finally:
            conn.close()
    if request.method == 'POST':
        fid     = request.form.get('faculty_id')
        course  = request.form.get('course_name', '').strip()
        credits = request.form.get('credit_hours')
        sem     = request.form.get('semester', '').strip()
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO workload (faculty_id, course_name, credit_hours, semester)
                    VALUES (%s, %s, %s, %s)
                """, (fid, course, credits, sem))
                conn.commit()
                flash('Workload entry added!', 'success')
                return redirect(url_for('workload'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('workload_form.html', action='Add', wl=None, faculty_list=faculty_list)

@app.route('/workload/edit/<int:wid>', methods=['GET', 'POST'])
@admin_required
def workload_edit(wid):
    conn = get_db()
    wl = None
    faculty_list = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT * FROM workload WHERE workload_id = %s", (wid,))
            wl = cur.fetchone()
            cur.execute("SELECT faculty_id, name FROM faculty ORDER BY name")
            faculty_list = cur.fetchall()
        finally:
            conn.close()
    if not wl:
        flash('Workload record not found.', 'danger')
        return redirect(url_for('workload'))
    if request.method == 'POST':
        fid     = request.form.get('faculty_id')
        course  = request.form.get('course_name', '').strip()
        credits = request.form.get('credit_hours')
        sem     = request.form.get('semester', '').strip()
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE workload SET faculty_id=%s, course_name=%s,
                    credit_hours=%s, semester=%s WHERE workload_id=%s
                """, (fid, course, credits, sem, wid))
                conn.commit()
                flash('Workload updated!', 'success')
                return redirect(url_for('workload'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('workload_form.html', action='Edit', wl=wl, faculty_list=faculty_list)

@app.route('/workload/delete/<int:wid>', methods=['POST'])
@admin_required
def workload_delete(wid):
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("DELETE FROM workload WHERE workload_id = %s", (wid,))
            conn.commit()
            flash('Workload entry deleted.', 'success')
        except Error as e:
            flash(f'Error: {str(e)}', 'danger')
        finally:
            conn.close()
    return redirect(url_for('workload'))

# ── Users (Admin only) ────────────────────────────────────────────────────────

@app.route('/users')
@admin_required
def users():
    conn = get_db()
    users_list = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("""
                SELECT u.*, f.name AS faculty_name
                FROM users u LEFT JOIN faculty f ON u.faculty_id = f.faculty_id
                ORDER BY u.user_id
            """)
            users_list = cur.fetchall()
        finally:
            conn.close()
    return render_template('users.html', users=users_list)

@app.route('/users/add', methods=['GET', 'POST'])
@admin_required
def user_add():
    conn = get_db()
    faculty_list = []
    if conn:
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT faculty_id, name FROM faculty ORDER BY name")
            faculty_list = cur.fetchall()
        finally:
            conn.close()
    if request.method == 'POST':
        uname  = request.form.get('username', '').strip()
        pwd    = request.form.get('password', '').strip()
        role   = request.form.get('role')
        fid    = request.form.get('faculty_id') or None
        conn = get_db()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO users (username, user_password, role, faculty_id)
                    VALUES (%s, %s, %s, %s)
                """, (uname, hash_password(pwd), role, fid))
                conn.commit()
                flash('User created!', 'success')
                return redirect(url_for('users'))
            except Error as e:
                flash(f'Error: {str(e)}', 'danger')
            finally:
                conn.close()
    return render_template('user_form.html', action='Add', user=None, faculty_list=faculty_list)

@app.route('/users/delete/<int:uid>', methods=['POST'])
@admin_required
def user_delete(uid):
    if uid == session.get('user_id'):
        flash("You cannot delete your own account.", 'danger')
        return redirect(url_for('users'))
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("DELETE FROM users WHERE user_id = %s", (uid,))
            conn.commit()
            flash('User deleted.', 'success')
        except Error as e:
            flash(f'Error: {str(e)}', 'danger')
        finally:
            conn.close()
    return redirect(url_for('users'))

# ─────────────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
