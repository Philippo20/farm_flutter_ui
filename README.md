# 🌱 AI Dashboard for Grow Room Monitoring

A cross-platform Flutter app for monitoring Farm Estates Grow Rooms.  
Built with **Flutter + Appwrite**, to provide real-time dashboards, role-based access, and smart alerts to help Farm Estates Owners and caretakers optimize crop growth.

---

## 🚀 Features
- **Real-time Monitoring**: Temperature, Humidity, CO₂, Light, pH, EC, Electricity, etc
- **Role-based Dashboards**:
  - **Admin** → Full system control, user & farm management
  - **Farm Owner** → Assigned farm dashboards, threshold settings, alerts
  - **Caretaker** → Assigned farm sensors, optional charts/logs
- **Alerts & Notifications**: Low pH, high EC, power issues, and more
- **Charts & Gauges**: Interactive graphs with `fl_chart` and `syncfusion_flutter_gauges`
- **Multi-language Support** with `easy_localization`
- **Modern UI**: Fresh green theme, Poppins & Roboto fonts, Lucide/Material icons

---

## 🛠 Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Appwrite (auth, DB, real-time)
- **Database Collections**: users, farms, sensors, alerts, thresholds, logs, grow_stages, and more
- **CI/CD**: GitHub Actions for test & build checks

---

## 📂 Project Structure

lib/
├─ constants/ # Colors, fonts, strings
├─ models/ # User, Sensor, Alert data
├─ providers/ # State management logic
├─ screens/ # Admin, Owner, Caretaker views
├─ services/ # API & Appwrite integration
├─ utils/ # Validators, helpers
├─ widgets/ # Reusable UI (Cards, Charts, Gauges)
└─ main.dart


---

## ▶️ Getting Started
1. Clone the repo:
   ```bash
   git clone https://github.com/<your-username>/farm_flutter_ui.git
   cd farmestates_ai_dashbaord
2. Install dependencies:
     ```bash
    flutter pub get
3. Configure environment (.env):
    ```bash
    APPWRITE_ENDPOINT=http://ip_address/v1
    APPWRITE_PROJECT_ID=project_id
    APPWRITE_API_KEY=your_api_key
    DATABASE_ID=
4. Run the app:
     ```bash
     flutter run
## BLOCK DIAGRAM
<img width="1668" height="1030" alt="image" src="https://github.com/user-attachments/assets/1dd53e7e-baae-4293-96d6-07e563b4cae0" />
<img width="1668" height="1057" alt="image" src="https://github.com/user-attachments/assets/59526c73-d280-4110-8026-cde4e7585642" />
<img width="1668" height="1053" alt="image" src="https://github.com/user-attachments/assets/6a7472c9-3f30-47a4-b404-e4176845e85e" />
<img width="1668" height="1021" alt="image" src="https://github.com/user-attachments/assets/9e49fbab-5c5e-4f2f-8956-aa4d2b1315ea" />
<img width="1668" height="967" alt="image" src="https://github.com/user-attachments/assets/f397a5bd-d219-454b-81be-20501e1caf15" />




     

