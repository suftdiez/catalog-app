import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  // GANTI IP INI:
  // Kalau pakai Emulator Android: pakai '10.0.2.2'
  // Kalau pakai HP Asli colok USB: pakai IP Laptop kamu (misal 192.168.1.5)
  // Kalau run di Chrome/Web: pakai 'localhost'
  final String serverIp = '10.0.2.2';

  late MqttServerClient client;

  Future<void> connect() async {
    client = MqttServerClient(serverIp, 'flutter_client_id');
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client_id')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      print('Sedang menghubungkan ke MQTT...');
      await client.connect();
    } catch (e) {
      print('Gagal koneksi MQTT: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('BERHASIL TERHUBUNG KE SERVER MING STACK!');
    } else {
      print('Koneksi Gagal, status: ${client.connectionStatus!.state}');
      client.disconnect();
    }
  }

  // Fungsi untuk lapor "Ada yang lihat produk ini"
  void laporLihatProduk(String namaProduk, int harga) {
    if (client.connectionStatus!.state != MqttConnectionState.connected) return;

    final builder = MqttClientPayloadBuilder();
    // Kirim data format teks: "iPhone 15,15000000"
    builder.addString('$namaProduk,$harga');

    // Kirim ke topik 'laporan/view'
    client.publishMessage('laporan/view', MqttQos.atLeastOnce, builder.payload!);
    print('Laporan terkirim: $namaProduk');
  }
}