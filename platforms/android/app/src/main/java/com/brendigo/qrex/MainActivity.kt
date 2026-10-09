package com.brendigo.qrex

import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color as AndroidColor
import android.net.Uri
import android.os.Bundle
import android.content.Context
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.zxing.BarcodeFormat
import com.google.zxing.MultiFormatWriter
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import java.text.DateFormat
import java.util.Date

private val midnight = Color(0xFF030C1B)
private val card = Color(0xFF101B2C)
private val cyan = Color(0xFF10C5FA)
private val purple = Color(0xFF9047F8)
private val white = Color.White

class MainActivity : ComponentActivity() {
    private val store by lazy { QREXStore(applicationContext) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { QREXApp(store) }
    }
}

@Composable
private fun QREXApp(store: QREXStore) {
    val pages = listOf("Skeniraj", "Stvori", "Povijest", "Više")
    val icons = listOf(Icons.Default.CameraAlt, Icons.Default.AddCircle,
        Icons.Default.History, Icons.Default.MoreHoriz)
    var selected by remember { mutableIntStateOf(0) }
    var currentCode by remember { mutableStateOf<String?>(null) }
    val colors = darkColorScheme(primary = cyan, secondary = purple,
        background = midnight, surface = card, onSurface = white, onBackground = white)
    MaterialTheme(colorScheme = colors) {
        Scaffold(containerColor = midnight, bottomBar = {
            NavigationBar(containerColor = Color(0xFF071225)) {
                pages.forEachIndexed { index, label ->
                    NavigationBarItem(selected = selected == index,
                        onClick = { selected = index; currentCode = null },
                        icon = { Icon(icons[index], contentDescription = label) },
                        label = { Text(label) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = cyan, selectedTextColor = cyan,
                            unselectedIconColor = Color.LightGray,
                            unselectedTextColor = Color.LightGray))
                }
            }
        }) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                if (currentCode != null) {
                    ResultScreen(currentCode!!, store, onClose = { currentCode = null })
                } else {
                    when (selected) {
                        0 -> ScanScreen(onRead = { raw ->
                            store.record(raw)
                            currentCode = raw
                        })
                        1 -> CreateScreen(store, onResult = { currentCode = it })
                        2 -> HistoryScreen(store, onOpen = { currentCode = it })
                        else -> MoreScreen(store)
                    }
                }
            }
        }
    }
}

@Composable
private fun AppHeader(title: String, subtitle: String) {
    Column(Modifier.fillMaxWidth().padding(bottom = 18.dp)) {
        Text(title, fontWeight = FontWeight.ExtraBold, fontSize = 28.sp, color = white)
        Spacer(Modifier.height(6.dp))
        Text(subtitle, fontSize = 13.sp, color = Color(0xFF9FB1CC))
    }
}

@Composable
private fun PrimaryAction(text: String, enabled: Boolean = true, onClick: () -> Unit) {
    Button(onClick = onClick, enabled = enabled,
        modifier = Modifier.fillMaxWidth().heightIn(min = 51.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1677FF))) {
        Text(text, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun ResultScreen(raw: String, store: QREXStore, onClose: () -> Unit) {
    val context = LocalContext.current
    val url = QRContent.safeUrl(raw)
    var showPassword by remember(raw) { mutableStateOf(false) }
    var confirmWifiSave by remember(raw) { mutableStateOf(false) }
    val wifi = QRContent.isWifi(raw)
    val alreadySaved = store.items.any { it.raw == raw && it.saved }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally) {
        Text("QREX", color = cyan, fontWeight = FontWeight.Black, fontSize = 29.sp)
        Spacer(Modifier.height(22.dp))
        Icon(Icons.Default.QrCode, contentDescription = null,
            tint = cyan, modifier = Modifier.size(68.dp))
        Spacer(Modifier.height(14.dp))
        Text("Skeniranje završeno", color = white, fontWeight = FontWeight.Bold,
            fontSize = 23.sp)
        Spacer(Modifier.height(18.dp))
        Surface(shape = RoundedCornerShape(20.dp), color = card) {
            Column(Modifier.fillMaxWidth().padding(18.dp)) {
                if (wifi) {
                    Text("Mreža: ${QRContent.wifiField(raw, "S") ?: "Wi-Fi"}",
                        fontWeight = FontWeight.Bold)
                    Text(if (showPassword)
                        "Lozinka: ${QRContent.wifiField(raw, "P") ?: ""}" else "Lozinka: ••••••••")
                    TextButton(onClick = { showPassword = !showPassword }) {
                        Text(if (showPassword) "Sakrij lozinku" else "Prikaži lozinku")
                    }
                } else {
                    Text(raw, color = white)
                    if (url != null) Text("Provjeri adresu prije otvaranja.",
                        color = Color.LightGray, fontSize = 12.sp)
                }
            }
        }
        Spacer(Modifier.height(15.dp))
        if (url != null) {
            PrimaryAction("Otvori poveznicu") { openLink(context, url) }
            Spacer(Modifier.height(10.dp))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            OutlinedButton(onClick = {
                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                clipboard.setPrimaryClip(android.content.ClipData.newPlainText("QR", raw))
                Toast.makeText(context, "Kopirano.", Toast.LENGTH_SHORT).show()
            }, modifier = Modifier.weight(1f)) {
                Icon(Icons.Default.ContentCopy, contentDescription = null)
                Spacer(Modifier.width(6.dp)); Text("Kopiraj")
            }
            OutlinedButton(onClick = {
                runCatching {
                    context.startActivity(Intent.createChooser(
                        Intent(Intent.ACTION_SEND).setType("text/plain")
                            .putExtra(Intent.EXTRA_TEXT, raw), "Podijeli QR"))
                }.onFailure { Toast.makeText(context,
                    "Dijeljenje nije dostupno.", Toast.LENGTH_SHORT).show() }
            }, modifier = Modifier.weight(1f)) {
                Icon(Icons.Default.Share, contentDescription = null)
                Spacer(Modifier.width(6.dp)); Text("Podijeli")
            }
        }
        Spacer(Modifier.height(12.dp))
        val bitmap = remember(raw) { generateQR(raw) }
        if (bitmap != null) {
            Image(bitmap.asImageBitmap(), contentDescription = "QR kod",
                modifier = Modifier.size(230.dp).background(white).padding(12.dp))
        }
        Spacer(Modifier.height(12.dp))
        PrimaryAction(if (alreadySaved) "Spremljeno" else "Spremi kod", enabled = !alreadySaved) {
            if (wifi) confirmWifiSave = true else store.save(raw)
        }
        Spacer(Modifier.height(10.dp))
        TextButton(onClick = onClose) { Text("Zatvori") }
    }
    if (confirmWifiSave) {
        AlertDialog(onDismissRequest = { confirmWifiSave = false },
            title = { Text("Spremanje Wi-Fi koda") },
            text = { Text("Spremit će se i Wi-Fi lozinka u lokalnu pohranu uređaja.") },
            confirmButton = { TextButton(onClick = {
                store.save(raw); confirmWifiSave = false
            }) { Text("Spremi") } },
            dismissButton = { TextButton(onClick = { confirmWifiSave = false }) { Text("Odustani") } })
    }
}

fun openLink(context: Context, url: Uri) {
    runCatching {
        context.startActivity(Intent(Intent.ACTION_VIEW, url))
    }.onFailure {
        Toast.makeText(context, "Poveznicu nije moguće otvoriti.", Toast.LENGTH_SHORT).show()
    }
}

fun generateQR(raw: String): Bitmap? {
    if (!QRContent.canRender(raw)) return null
    return runCatching {
        val bits = MultiFormatWriter().encode(raw, BarcodeFormat.QR_CODE, 680, 680,
            mapOf(EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M,
                EncodeHintType.MARGIN to 2))
        val bitmap = Bitmap.createBitmap(bits.width, bits.height, Bitmap.Config.ARGB_8888)
        val data = IntArray(bits.width * bits.height) { index ->
            if (bits[index % bits.width, index / bits.width]) AndroidColor.BLACK
            else AndroidColor.WHITE
        }
        bitmap.setPixels(data, 0, bits.width, 0, 0, bits.width, bits.height)
        bitmap
    }.getOrNull()
}

@Composable
private fun CreateScreen(store: QREXStore, onResult: (String) -> Unit) {
    val types = listOf("Poveznica", "Tekst", "Wi-Fi", "E-mail", "Telefon", "Lokacija", "Kontakt")
    var kind by remember { mutableIntStateOf(0) }
    var content by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var reveal by remember { mutableStateOf(false) }
    var more by remember { mutableStateOf(false) }
    val input = content.trim()
    val payload = when (kind) {
        0 -> if (QRContent.safeUrl(input) != null) input else ""
        1 -> input
        2 -> if (input.isBlank()) "" else QRContent.wifi(input, password)
        3 -> if (input.contains("@") && !input.contains("\n")) "mailto:$input" else ""
        4 -> if (input.isBlank()) "" else "tel:$input"
        5 -> if (input.isBlank()) "" else "geo:$input"
        else -> if (input.isBlank()) "" else
            "BEGIN:VCARD\nVERSION:3.0\nFN:${input.replace("\n", " ")}\nEND:VCARD"
    }
    val qr = remember(payload) { generateQR(payload) }

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp)) {
        AppHeader("Stvori QR kod", "Odaberi vrstu i unesi podatke.")
        types.take(if (more) types.size else 3).chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                row.forEach { type ->
                    val index = types.indexOf(type)
                    FilterChip(selected = kind == index,
                        onClick = { kind = index; content = ""; password = "" },
                        label = { Text(type) })
                    Spacer(Modifier.width(5.dp))
                }
            }
        }
        TextButton(onClick = { more = !more; if (!more && kind > 2) kind = 0 }) {
            Text(if (more) "Manje mogućnosti" else "Više mogućnosti")
        }
        Spacer(Modifier.height(10.dp))
        OutlinedTextField(value = content, onValueChange = { content = it.take(2000) },
            modifier = Modifier.fillMaxWidth(), label = { Text(types[kind]) },
            keyboardOptions = KeyboardOptions(keyboardType =
                if (kind == 0) KeyboardType.Uri else KeyboardType.Text))
        if (kind == 2) {
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(value = password, onValueChange = { password = it.take(500) },
                modifier = Modifier.fillMaxWidth(), label = { Text("Lozinka (neobavezno)") },
                visualTransformation = if (reveal) VisualTransformation.None else PasswordVisualTransformation(),
                trailingIcon = {
                    TextButton(onClick = { reveal = !reveal }) {
                        Text(if (reveal) "Sakrij" else "Prikaži")
                    }
                })
            Text("Wi-Fi QR kod može sadržavati lozinku.", fontSize = 12.sp,
                color = Color.LightGray)
        }
        Spacer(Modifier.height(18.dp))
        Surface(shape = RoundedCornerShape(22.dp), color = card,
            modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(18.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Pregled koda", fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(16.dp))
                if (qr != null) Image(qr.asImageBitmap(), contentDescription = "QR kod",
                    modifier = Modifier.size(238.dp).background(white).padding(14.dp))
                else Text("Unesi valjane podatke za QR kod.", color = Color.LightGray)
            }
        }
        Spacer(Modifier.height(12.dp))
        PrimaryAction("Prikaži QR kod", enabled = qr != null) { onResult(payload) }
        Spacer(Modifier.height(10.dp))
        OutlinedButton(onClick = { store.save(payload) }, enabled = qr != null,
            modifier = Modifier.fillMaxWidth()) { Text("Spremi kod") }
    }
}

@Composable
private fun HistoryScreen(store: QREXStore, onOpen: (String) -> Unit) {
    var search by remember { mutableStateOf("") }
    val found = store.items.filter { QRContent.label(it.raw).contains(search, ignoreCase = true) }
    Column(Modifier.fillMaxSize().padding(20.dp)) {
        AppHeader("Povijest", "Spremljeni QR kodovi na uređaju.")
        OutlinedTextField(value = search, onValueChange = { search = it },
            label = { Text("Pretraži kodove") }, modifier = Modifier.fillMaxWidth())
        Spacer(Modifier.height(12.dp))
        if (found.isEmpty) {
            Text("Nema spremljenih kodova.", color = Color.LightGray)
        }
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(found, key = { it.raw }) { item ->
                Surface(shape = RoundedCornerShape(15.dp), color = card) {
                    Row(Modifier.fillMaxWidth().padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        TextButton(onClick = { onOpen(item.raw) }, modifier = Modifier.weight(1f)) {
                            Column(horizontalAlignment = Alignment.Start) {
                                Text(QRContent.label(item.raw), color = white)
                                Text(DateFormat.getDateTimeInstance().format(Date(item.timestamp)),
                                    color = Color.LightGray, fontSize = 11.sp)
                            }
                        }
                        IconButton(onClick = { store.remove(item) }) {
                            Icon(Icons.Default.Delete, contentDescription = "Izbriši", tint = Color.LightGray)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MoreScreen(store: QREXStore) {
    val context = LocalContext.current
    var showDelete by remember { mutableStateOf(false) }
    var showPrivacy by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp)) {
        AppHeader("Više", "Sve na jednom mjestu.")
        Text("Postavke", color = white, fontSize = 20.sp, fontWeight = FontWeight.Bold)
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("Spremanje povijesti", Modifier.weight(1f))
            Switch(checked = store.historyEnabled, onCheckedChange = store::setHistoryEnabled)
        }
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("Svijetli izgled", Modifier.weight(1f))
            Switch(checked = store.lightMode, onCheckedChange = store::setLightMode)
        }
        OutlinedButton(onClick = { showDelete = true }) { Text("Izbriši sve podatke") }
        Spacer(Modifier.height(20.dp))
        Text("Privatnost", color = white, fontSize = 20.sp, fontWeight = FontWeight.Bold)
        TextButton(onClick = { showPrivacy = true }) { Text("Pravila privatnosti") }
        Spacer(Modifier.height(20.dp))
        Text("O aplikaciji", color = white, fontSize = 20.sp, fontWeight = FontWeight.Bold)
        Text("QREX", color = Color.LightGray)
        TextButton(onClick = {
            openLink(context, Uri.parse("https://brendigo.com"))
        }) { Text("Razvio Brendigo") }
    }
    if (showDelete) AlertDialog(onDismissRequest = { showDelete = false },
        title = { Text("Izbriši sve podatke?") },
        text = { Text("Trajno se brišu povijest, spremljeni QR kodovi i postavke.") },
        confirmButton = { TextButton(onClick = { store.clearAll(); showDelete = false }) { Text("Izbriši sve") } },
        dismissButton = { TextButton(onClick = { showDelete = false }) { Text("Odustani") } })
    if (showPrivacy) AlertDialog(onDismissRequest = { showPrivacy = false },
        title = { Text("Pravila privatnosti") },
        text = { Text("QREX obrađuje QR kodove lokalno, bez prijave, oglasa i analitike. Povijest je opcionalna, Wi-Fi kodovi se ne spremaju automatski, a ručno spremljeni mogu sadržavati lozinku. Vanjske radnje mogu predati podatke drugoj aplikaciji. Svi lokalni podaci mogu se izbrisati ovdje. Za kontakt posjeti brendigo.com.") },
        confirmButton = { TextButton(onClick = { showPrivacy = false }) { Text("Zatvori") } })
}
