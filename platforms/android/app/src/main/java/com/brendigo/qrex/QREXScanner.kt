package com.brendigo.qrex

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.atomic.AtomicBoolean

@OptIn(androidx.camera.core.ExperimentalGetImage::class)
@Composable
fun ScanScreen(onRead: (String) -> Unit) {
    val context = LocalContext.current
    val owner = LocalLifecycleOwner.current
    var allowed by remember {
        mutableStateOf(ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED)
    }
    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {
        allowed = it
    }
    var message by remember { mutableStateOf<String?>(null) }
    val handled = remember { AtomicBoolean(false) }
    val options = remember {
        BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE).build()
    }
    val photoPicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri != null) {
            val image = runCatching { InputImage.fromFilePath(context, uri) }.getOrNull()
            if (image == null) {
                message = "Fotografiju nije moguće otvoriti."
            } else {
                val client = BarcodeScanning.getClient(options)
                client.process(image).addOnSuccessListener { codes ->
                    val raw = codes.firstOrNull { it.format == Barcode.FORMAT_QR_CODE }?.rawValue
                    if (!raw.isNullOrEmpty()) {
                        if (handled.compareAndSet(false, true)) onRead(raw)
                    } else message = "Na fotografiji nije pronađen QR kod."
                }.addOnFailureListener {
                    message = "Fotografiju nije moguće pročitati."
                }.addOnCompleteListener { client.close() }
            }
        }
    }

    LaunchedEffect(Unit) {
        if (!allowed) permission.launch(Manifest.permission.CAMERA)
    }
    Column(Modifier.fillMaxSize().padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text("QREX", color = Color(0xFF10C5FA),
            style = MaterialTheme.typography.headlineLarge)
        Spacer(Modifier.height(12.dp))
        Text("Skeniraj QR kod", style = MaterialTheme.typography.titleLarge)
        Spacer(Modifier.height(20.dp))
        if (allowed) {
            val preview = remember { PreviewView(context) }
            DisposableEffect(owner, allowed) {
                val cameraFuture = ProcessCameraProvider.getInstance(context)
                val disposed = AtomicBoolean(false)
                val scanner = BarcodeScanning.getClient(options)
                cameraFuture.addListener({
                    if (disposed.get()) return@addListener
                    runCatching {
                        val provider = cameraFuture.get()
                        val cameraPreview = Preview.Builder().build().also {
                            it.surfaceProvider = preview.surfaceProvider
                        }
                        val analyzer = ImageAnalysis.Builder()
                            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                            .build()
                        analyzer.setAnalyzer(ContextCompat.getMainExecutor(context)) { frame ->
                            fun process() {
                                val media = frame.image
                                if (media == null || handled.get()) { frame.close(); return }
                                val input = InputImage.fromMediaImage(media,
                                    frame.imageInfo.rotationDegrees)
                                scanner.process(input).addOnSuccessListener { codes ->
                                    val value = codes.firstOrNull { it.format == Barcode.FORMAT_QR_CODE }?.rawValue
                                    if (!value.isNullOrEmpty() && handled.compareAndSet(false, true)) onRead(value)
                                }.addOnCompleteListener { frame.close() }
                            }
                            process()
                        }
                        provider.unbindAll()
                        provider.bindToLifecycle(owner, CameraSelector.DEFAULT_BACK_CAMERA,
                            cameraPreview, analyzer)
                    }.onFailure { message = "Kamera trenutačno nije dostupna." }
                }, ContextCompat.getMainExecutor(context))
                onDispose {
                    disposed.set(true)
                    if (cameraFuture.isDone) runCatching { cameraFuture.get().unbindAll() }
                    scanner.close()
                }
            }
            AndroidView(factory = { preview }, modifier = Modifier
                .fillMaxWidth().weight(1f)
                .background(Color(0xFF101B2C), shape = RoundedCornerShape(28.dp)))
        } else {
            Box(Modifier.fillMaxWidth().weight(1f)
                .background(Color(0xFF101B2C), shape = RoundedCornerShape(28.dp)),
                contentAlignment = Alignment.Center) {
                Text("Omogući kameru u postavkama uređaja za skeniranje QR kodova.",
                    modifier = Modifier.padding(20.dp))
            }
        }
        Spacer(Modifier.height(16.dp))
        OutlinedButton(onClick = { photoPicker.launch("image/*") }) {
            Text("Skeniraj iz slike")
        }
        Spacer(Modifier.height(8.dp))
        Text("Usmjeri kameru prema QR kodu.", color = Color.LightGray)
    }

    if (message != null) AlertDialog(onDismissRequest = { message = null },
        title = { Text("QREX") },
        text = { Text(message ?: "") },
        confirmButton = { TextButton(onClick = { message = null }) { Text("U redu") } })
}
