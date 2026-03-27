import streamlit as st
import pandas as pd

# -------------------------
# PAGE CONFIG
# -------------------------
st.set_page_config(page_title="Uber Dashboard", layout="wide")

st.title("🚖 Uber Analytics Dashboard")

# -------------------------
# LOAD DATA (CSV)
# -------------------------
@st.cache_data
def load_data():
    df = pd.read_csv("uber_data.csv")
    df["pickup_time"] = pd.to_datetime(df["pickup_time"])
    df["drop_time"] = pd.to_datetime(df["drop_time"])
    return df

df = load_data()

# -------------------------
# SIDEBAR FILTERS
# -------------------------
st.sidebar.header("🎛️ Filters")

# City
cities = df["city"].unique().tolist()
selected_city = st.sidebar.selectbox("City", ["All"] + cities)

# Payment
payments = df["payment_method"].unique().tolist()
selected_payment = st.sidebar.selectbox("Payment Method", ["All"] + payments)

# Status
status_list = df["status"].unique().tolist()
selected_status = st.sidebar.selectbox("Trip Status", ["All"] + status_list)

# Date
min_date = df["pickup_time"].min().date()
max_date = df["pickup_time"].max().date()

date_range = st.sidebar.date_input("Date Range", [min_date, max_date])

# -------------------------
# APPLY FILTERS
# -------------------------
filtered_df = df.copy()

if selected_city != "All":
    filtered_df = filtered_df[filtered_df["city"] == selected_city]

if selected_payment != "All":
    filtered_df = filtered_df[
        filtered_df["payment_method"] == selected_payment
    ]

if selected_status != "All":
    filtered_df = filtered_df[filtered_df["status"] == selected_status]

filtered_df = filtered_df[
    (filtered_df["pickup_time"].dt.date >= date_range[0]) &
    (filtered_df["pickup_time"].dt.date <= date_range[1])
]

# -------------------------
# KPI SECTION
# -------------------------
st.subheader("📊 Key Metrics")

total_trips = len(filtered_df)
total_revenue = filtered_df["fare_amount"].sum()
avg_distance = filtered_df["distance_km"].mean()

col1, col2, col3 = st.columns(3)

col1.metric("Total Trips", total_trips)
col2.metric("Total Revenue", f"₹{round(total_revenue,2)}")
col3.metric("Avg Distance (km)", round(avg_distance, 2))

# -------------------------
# PEAK HOURS
# -------------------------
st.subheader("🕐 Peak Hours")

hour_df = filtered_df.copy()
hour_df["hour"] = hour_df["pickup_time"].dt.hour

hour_chart = hour_df.groupby("hour").size()

st.line_chart(hour_chart)

# -------------------------
# REVENUE TREND
# -------------------------
st.subheader("💰 Revenue Trend")

day_df = filtered_df.copy()
day_df["day"] = day_df["pickup_time"].dt.date

revenue_chart = day_df.groupby("day")["fare_amount"].sum()

st.line_chart(revenue_chart)

# -------------------------
# INSIGHTS
# -------------------------
st.subheader("📌 Key Insights")

st.write(f"""
- Total Trips: {total_trips}
- Total Revenue: ₹{round(total_revenue,2)}
- Average Distance: {round(avg_distance,2)} km

### Filters Applied:
- City: {selected_city}
- Payment: {selected_payment}
- Status: {selected_status}
- Date Range: {date_range[0]} to {date_range[1]}
""")