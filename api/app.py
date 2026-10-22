import os
from flask import Flask, request, jsonify, make_response
import joblib
import pandas as pd

app = Flask(__name__)

# Path absolut ke folder api/ agar benar dari manapun dijalankan
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Memuat model dan encoder
model = joblib.load(os.path.join(BASE_DIR, "dcare_naive_bayes_model.pkl"))
feature_encoders = joblib.load(os.path.join(BASE_DIR, "dcare_feature_encoders.pkl"))
target_encoder = joblib.load(os.path.join(BASE_DIR, "dcare_target_encoder.pkl"))


# ── CORS: tambahkan header ke SEMUA response (termasuk preflight OPTIONS) ──────
@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    return response


# ── Handle preflight OPTIONS request dari browser ──────────────────────────────
@app.route("/predict", methods=["OPTIONS"])
def predict_options():
    return make_response("", 204)


@app.route("/")
def home():
    return jsonify({"status": "ok", "message": "API D'Care berhasil berjalan"})


@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json(force=True)
        if not data:
            return jsonify({"error": "Request body kosong"}), 400

        # ── Ambil nilai mentah dari Flutter ─────────────────────────────────
        jk_raw     = data.get("JK", "Laki-Laki")          # "Laki-Laki" | "Perempuan"
        usia_raw   = int(data.get("Usia", 0))              # angka usia
        imt_raw    = float(data.get("IMT", 0.0))           # angka IMT
        hipertensi = data.get("Hipertensi", False)         # True/False
        kardio     = data.get("Riwayat Kardiovaskuler", False)
        merokok    = data.get("Riwayat Merokok", False)
        keluarga   = data.get("Riwayat Keluarga", False)

        # ── Konversi ke format yang dipakai saat training ────────────────────
        # JK: model pakai "Laki - Laki" (spasi di sekitar strip)
        jk_encoded = "Laki - Laki" if jk_raw == "Laki-Laki" else "Perempuan"

        # Usia: model pakai kategori string, bukan angka
        usia_encoded = "Diatas 45" if usia_raw > 45 else "Dibawah 45"

        # IMT: model pakai kategori string, bukan angka
        if imt_raw < 23.0:
            imt_encoded = "Normal"
        elif imt_raw < 27.5:
            imt_encoded = "Beresiko"
        elif imt_raw < 32.0:
            imt_encoded = "Obes 1"
        else:
            imt_encoded = "Obes 2"

        # Boolean → "Iya"/"Tidak" (model pakai "Iya", bukan "Ya")
        def yn(val):
            return "Iya" if val else "Tidak"

        input_dict = {
            "JK": jk_encoded,
            "Usia": usia_encoded,
            "IMT": imt_encoded,
            "Hipertensi": yn(hipertensi),
            "Riwayat Kardiovaskuler": yn(kardio),
            "Riwayat Merokok": yn(merokok),
            "Riwayat Keluarga": yn(keluarga),
        }

        # Membuat DataFrame
        input_data = pd.DataFrame([input_dict])

        # Urutan kolom harus sama seperti saat model dilatih
        kolom_urutan = [
            "JK",
            "Usia",
            "IMT",
            "Hipertensi",
            "Riwayat Kardiovaskuler",
            "Riwayat Merokok",
            "Riwayat Keluarga",
        ]
        input_data = input_data[kolom_urutan]

        # Encoding setiap kolom dengan encoder masing-masing
        for col in input_data.columns:
            input_data[col] = feature_encoders[col].transform(input_data[col])

        # Prediksi
        hasil = model.predict(input_data)

        # Mengubah hasil angka menjadi label asli
        hasil_label = target_encoder.inverse_transform(hasil)

        return jsonify({"hasil": hasil_label[0]})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)