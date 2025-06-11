package com.example.udyothvi

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import coil.compose.rememberAsyncImagePainter
import com.canhub.cropper.CropImageContract
import com.canhub.cropper.CropImageContractOptions
import com.canhub.cropper.CropImageOptions
import com.canhub.cropper.CropImageView
import java.io.File
import java.io.FileOutputStream
import java.util.*
import kotlin.math.roundToInt
import androidx.navigation.NavController
import androidx.lifecycle.viewmodel.compose.viewModel

sealed class Screen {
    object Main : Screen()
    object Filter : Screen()
    object Adjust : Screen()
    data class Crop(val uri: Uri) : Screen()
}

class ProfileActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    ProfileScreen(
                        onBack = { finish() },
                        onSaveAndContinue = { visibility ->
                            val intent = Intent(this, NextActivity::class.java)
                            intent.putExtra("visibility", visibility)
                            startActivity(intent)
                        },
                        onSkip = {
                            val intent = Intent(this, NextActivity::class.java)
                            intent.putExtra("visibility", "Private")
                            startActivity(intent)
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun ProfileScreen(
    onBack: () -> Unit,
    onSaveAndContinue: (String) -> Unit,
    onSkip: () -> Unit
) {
    var currentScreen by remember { mutableStateOf<Screen>(Screen.Main) }
    var profileImageBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var imageUri by remember { mutableStateOf<Uri?>(null) }
    var isPublic by remember { mutableStateOf<Boolean>(false) }
    var showEditingOptions by remember { mutableStateOf<Boolean>(false) }
    
    val context = LocalContext.current

    // Permission launcher
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (permissions.all { it.value }) {
            Toast.makeText(context, "Permissions granted", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(context, "Permissions denied", Toast.LENGTH_SHORT).show()
        }
    }

    // Gallery launcher
    val galleryLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            imageUri = it
            profileImageBitmap = null
            showEditingOptions = true
        }
    }

    // Camera launcher
    val cameraLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicturePreview()
    ) { bitmap ->
        bitmap?.let {
            profileImageBitmap = it
            imageUri = null
            showEditingOptions = true
        }
    }

    // Crop launcher
    val cropImage = rememberLauncherForActivityResult(CropImageContract()) { result ->
        if (result.isSuccessful) {
            result.uriContent?.let { uri ->
                try {
                    // Convert Uri to Bitmap
                    val inputStream = context.contentResolver.openInputStream(uri)
                    val bitmap = BitmapFactory.decodeStream(inputStream)
                    profileImageBitmap = bitmap
                    imageUri = null
                    showEditingOptions = true
                    Toast.makeText(context, "Image cropped successfully", Toast.LENGTH_SHORT).show()
                } catch (e: Exception) {
                    Toast.makeText(context, "Failed to load cropped image", Toast.LENGTH_SHORT).show()
                    e.printStackTrace()
                }
            }
        } else {
            val error = result.error
            Toast.makeText(context, "Crop failed: $error", Toast.LENGTH_SHORT).show()
        }
        currentScreen = Screen.Main
    }

    // Request permissions
    LaunchedEffect(Unit) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_MEDIA_IMAGES) != PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            permissionLauncher.launch(
                arrayOf(Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.CAMERA)
            )
        }
    }

    when (currentScreen) {
        Screen.Main -> MainScreen(
            imageUri = imageUri,
            profileImageBitmap = profileImageBitmap,
            isPublic = isPublic,
            showEditingOptions = showEditingOptions,
            onGalleryClick = { galleryLauncher.launch("image/*") },
            onCameraClick = { cameraLauncher.launch(null) },
            onRemovePhoto = {
                imageUri = null
                profileImageBitmap = null
                showEditingOptions = false
                Toast.makeText(context, "Profile photo removed", Toast.LENGTH_SHORT).show()
            },
            onCropClick = {
                if (imageUri != null || profileImageBitmap != null) {
                    val sourceUri = if (imageUri != null) {
                        imageUri
                    } else {
                        // Convert bitmap to Uri
                        saveBitmapToCache(context, profileImageBitmap!!)
                    }

                    sourceUri?.let { uri ->
                        val cropOptions = CropImageOptions().apply {
                            cropShape = CropImageView.CropShape.OVAL
                            fixAspectRatio = true
                            aspectRatioX = 1
                            aspectRatioY = 1
                            guidelines = CropImageView.Guidelines.ON
                            outputCompressFormat = Bitmap.CompressFormat.PNG
                            outputCompressQuality = 95
                            activityTitle = "Crop photo"
                            cropMenuCropButtonTitle = "Save"
                            showCropOverlay = true
                            showProgressBar = true
                        }
                        
                        cropImage.launch(
                            CropImageContractOptions(
                                uri = uri,
                                cropImageOptions = cropOptions
                            )
                        )
                    }
                } else {
                    Toast.makeText(context, "Please select an image first", Toast.LENGTH_SHORT).show()
                }
            },
            onFilterClick = { currentScreen = Screen.Filter },
            onAdjustClick = { currentScreen = Screen.Adjust },
            onVisibilityChange = { checked ->
                isPublic = checked
                Toast.makeText(
                    context,
                    "Your profile has been set to ${if (checked) "Public" else "Private"}",
                    Toast.LENGTH_SHORT
                ).show()
            },
            onSaveAndContinue = { onSaveAndContinue(if (isPublic) "Public" else "Private") },
            onBack = onBack,
            onSkip = onSkip
        )
        
        is Screen.Crop -> {
            val cropUri = (currentScreen as Screen.Crop).uri
            CropPreviewScreen(
                croppedUri = cropUri,
                onSave = {
                    try {
                        // Convert Uri to Bitmap
                        val inputStream = context.contentResolver.openInputStream(cropUri)
                        val bitmap = BitmapFactory.decodeStream(inputStream)
                        profileImageBitmap = bitmap
                        imageUri = null
                        showEditingOptions = true
                        Toast.makeText(context, "Cropped image saved successfully", Toast.LENGTH_SHORT).show()
                        currentScreen = Screen.Main
                    } catch (e: Exception) {
                        Toast.makeText(context, "Failed to save cropped image", Toast.LENGTH_SHORT).show()
                        e.printStackTrace()
                    }
                },
                onCancel = {
                    currentScreen = Screen.Main
                }
            )
        }
        
        Screen.Filter -> {
            val bitmap = if (imageUri != null) {
                // Load bitmap from Uri
                val inputStream = context.contentResolver.openInputStream(imageUri!!)
                BitmapFactory.decodeStream(inputStream)
            } else {
                profileImageBitmap
            }
            
            FilterScreen(
                bitmap = bitmap,
                onFilterApplied = { filteredBitmap ->
                    profileImageBitmap = filteredBitmap
                    imageUri = null
                    currentScreen = Screen.Main
                },
                onBack = { currentScreen = Screen.Main }
            )
        }
        
        Screen.Adjust -> {
            val bitmap = if (imageUri != null) {
                // Load bitmap from Uri
                val inputStream = context.contentResolver.openInputStream(imageUri!!)
                BitmapFactory.decodeStream(inputStream)
            } else {
                profileImageBitmap
            }
            
            AdjustScreen(
                bitmap = bitmap,
                onAdjustComplete = { adjustedBitmap ->
                    profileImageBitmap = adjustedBitmap
                    imageUri = null
                    currentScreen = Screen.Main
                },
                onBack = { currentScreen = Screen.Main }
            )
        }
    }
}

@Composable
fun MainScreen(
    imageUri: Uri?,
    profileImageBitmap: Bitmap?,
    isPublic: Boolean,
    showEditingOptions: Boolean,
    onGalleryClick: () -> Unit,
    onCameraClick: () -> Unit,
    onRemovePhoto: () -> Unit,
    onCropClick: () -> Unit,
    onFilterClick: () -> Unit,
    onAdjustClick: () -> Unit,
    onVisibilityChange: (Boolean) -> Unit,
    onSaveAndContinue: () -> Unit,
    onBack: () -> Unit,
    onSkip: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Title with back button
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Start,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = "Back",
                    tint = Color(0xFF8A2BE2)
                )
            }
            Text(
                text = "Profile Setup",
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Profile Image
        Box(
            modifier = Modifier
                .size(200.dp)
                .clip(CircleShape)
                .background(Color(0xFFE0E0E0)),
            contentAlignment = Alignment.Center
        ) {
            if (imageUri != null) {
                Image(
                    painter = rememberAsyncImagePainter(imageUri),
                    contentDescription = "Profile Image",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            } else if (profileImageBitmap != null) {
                Image(
                    bitmap = profileImageBitmap.asImageBitmap(),
                    contentDescription = "Profile Image",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            } else {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = "Profile Placeholder",
                        modifier = Modifier.size(64.dp),
                        tint = Color(0xFF9E9E9E)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Add Photo",
                        fontSize = 16.sp,
                        color = Color(0xFF757575)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Image Source Buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Button(
                onClick = onGalleryClick,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2)),
                shape = RoundedCornerShape(24.dp),
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = "Gallery",
                    color = Color.White,
                    maxLines = 1,
                    softWrap = false
                )
            }
            Button(
                onClick = onCameraClick,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2)),
                shape = RoundedCornerShape(24.dp),
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = "Camera",
                    color = Color.White,
                    maxLines = 1,
                    softWrap = false
                )
            }
            Button(
                onClick = onRemovePhoto,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2)),
                shape = RoundedCornerShape(24.dp),
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = "Remove",
                    color = Color.White,
                    maxLines = 1,
                    softWrap = false
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Editing Options
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.clickable(onClick = onCropClick)
            ) {
                Icon(
                    imageVector = Icons.Default.Crop,
                    contentDescription = "Crop",
                    tint = Color(0xFF8A2BE2),
                    modifier = Modifier.size(24.dp)
                )
                Text(
                    text = "Crop",
                    fontSize = 12.sp,
                    color = Color(0xFF8A2BE2)
                )
            }

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.clickable(onClick = onFilterClick)
            ) {
                Icon(
                    imageVector = Icons.Default.FilterAlt,
                    contentDescription = "Filter",
                    tint = Color(0xFF8A2BE2),
                    modifier = Modifier.size(24.dp)
                )
                Text(
                    text = "Filter",
                    fontSize = 12.sp,
                    color = Color(0xFF8A2BE2)
                )
            }

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.clickable(onClick = onAdjustClick)
            ) {
                Icon(
                    imageVector = Icons.Default.Tune,
                    contentDescription = "Adjust",
                    tint = Color(0xFF8A2BE2),
                    modifier = Modifier.size(24.dp)
                )
                Text(
                    text = "Adjust",
                    fontSize = 12.sp,
                    color = Color(0xFF8A2BE2)
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        // Profile Visibility
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Profile Visibility:",
                    style = MaterialTheme.typography.bodyLarge
                )
                Switch(
                    checked = isPublic,
                    onCheckedChange = onVisibilityChange,
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Color(0xFF8A2BE2),
                        checkedTrackColor = Color(0xFF8A2BE2).copy(alpha = 0.5f)
                    )
                )
            }
            
            if (isPublic) {
                Snackbar(
                    modifier = Modifier.padding(vertical = 8.dp),
                    containerColor = Color(0xFF4CAF50).copy(alpha = 0.1f),
                    contentColor = Color(0xFF4CAF50)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Your profile has been set to Public")
                    }
                }
            }
        }

        // Bottom navigation
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Save button in middle
            Row(
                modifier = Modifier
                    .fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                Button(
                    onClick = onSaveAndContinue,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2)),
                    shape = RoundedCornerShape(24.dp),
                    modifier = Modifier.width(200.dp)
                ) {
                    Text("Save and Next")
                }
            }
            
            // Skip button at bottom right
            Row(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .clickable(onClick = onSkip),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Skip",
                    color = Color(0xFF8A2BE2)
                )
                Icon(
                    imageVector = Icons.Default.ArrowForward,
                    contentDescription = "Skip",
                    tint = Color(0xFF8A2BE2),
                    modifier = Modifier.padding(start = 4.dp)
                )
            }
        }
    }
}

fun saveBitmapToCache(context: Context, bitmap: Bitmap): Uri? {
    return try {
        // Create a file in the cache directory
        val cachePath = File(context.cacheDir, "images")
        cachePath.mkdirs()
        val file = File(cachePath, "temp_${UUID.randomUUID()}.png")
        
        // Save the bitmap to the file
        FileOutputStream(file).use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 95, stream)
            stream.flush()
        }
        
        // Convert the file to a URI
        Uri.fromFile(file)
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
}

@Composable
fun CropPreviewScreen(
    croppedUri: Uri,
    onSave: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Image(
                painter = rememberAsyncImagePainter(croppedUri),
                contentDescription = "Cropped Image Preview",
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Fit
            )
        }
        
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            Button(
                onClick = onCancel,
                colors = ButtonDefaults.buttonColors(containerColor = Color.Gray)
            ) {
                Text("Cancel")
            }
            
            Button(onClick = onSave) {
                Text("Save")
            }
        }
    }
}

@Composable
fun FilterScreen(
    bitmap: Bitmap?,
    onFilterApplied: (Bitmap) -> Unit,
    onBack: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        CenterAlignedTopAppBar(
            title = { Text("Apply Filter") },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
            },
            colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
                navigationIconContentColor = MaterialTheme.colorScheme.onPrimaryContainer
            )
        )

        if (bitmap != null) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Image(
                    bitmap = bitmap.asImageBitmap(),
                    contentDescription = "Image to Filter",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Fit
                )
            }

            // Filter options
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(listOf("Normal", "Grayscale", "Sepia", "Vintage")) { filter ->
                    FilterOption(
                        name = filter,
                        onClick = {
                            // Apply the selected filter
                            val filteredBitmap = when (filter) {
                                "Grayscale" -> applyGrayscaleFilter(bitmap)
                                "Sepia" -> applySepiaFilter(bitmap)
                                "Vintage" -> applyVintageFilter(bitmap)
                                else -> bitmap
                            }
                            onFilterApplied(filteredBitmap)
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun FilterOption(
    name: String,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier.padding(4.dp)
    ) {
        Text(name)
    }
}

// Filter utility functions
private fun applyGrayscaleFilter(source: Bitmap): Bitmap {
    val width = source.width
    val height = source.height
    val result = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    
    for (x in 0 until width) {
        for (y in 0 until height) {
            val pixel = source.getPixel(x, y)
            val r = android.graphics.Color.red(pixel)
            val g = android.graphics.Color.green(pixel)
            val b = android.graphics.Color.blue(pixel)
            val a = android.graphics.Color.alpha(pixel)
            val gray = (r * 0.299f + g * 0.587f + b * 0.114f).roundToInt().coerceIn(0, 255)
            val newPixel = android.graphics.Color.argb(a, gray, gray, gray)
            result.setPixel(x, y, newPixel)
        }
    }
    return result
}

private fun applySepiaFilter(source: Bitmap): Bitmap {
    val width = source.width
    val height = source.height
    val result = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    
    for (x in 0 until width) {
        for (y in 0 until height) {
            val pixel = source.getPixel(x, y)
            val a = android.graphics.Color.alpha(pixel)
            val r = android.graphics.Color.red(pixel)
            val g = android.graphics.Color.green(pixel)
            val b = android.graphics.Color.blue(pixel)
            
            val tr = (r * 0.393f + g * 0.769f + b * 0.189f).roundToInt().coerceIn(0, 255)
            val tg = (r * 0.349f + g * 0.686f + b * 0.168f).roundToInt().coerceIn(0, 255)
            val tb = (r * 0.272f + g * 0.534f + b * 0.131f).roundToInt().coerceIn(0, 255)
            
            val newPixel = android.graphics.Color.argb(a, tr, tg, tb)
            result.setPixel(x, y, newPixel)
        }
    }
    return result
}

private fun applyVintageFilter(source: Bitmap): Bitmap {
    val width = source.width
    val height = source.height
    val result = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    
    for (x in 0 until width) {
        for (y in 0 until height) {
            val pixel = source.getPixel(x, y)
            val a = android.graphics.Color.alpha(pixel)
            val r = android.graphics.Color.red(pixel)
            val g = android.graphics.Color.green(pixel)
            val b = android.graphics.Color.blue(pixel)
            
            val tr = (r * 0.9f + g * 0.1f).roundToInt().coerceIn(0, 255)
            val tg = (g * 0.9f + b * 0.1f).roundToInt().coerceIn(0, 255)
            val tb = (b * 0.9f + r * 0.1f).roundToInt().coerceIn(0, 255)
            
            val newPixel = android.graphics.Color.argb(a, tr, tg, tb)
            result.setPixel(x, y, newPixel)
        }
    }
    return result
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdjustScreen(
    bitmap: Bitmap?,
    onAdjustComplete: (Bitmap) -> Unit,
    onBack: () -> Unit
) {
    var brightness by remember { mutableFloatStateOf(0f) }
    var contrast by remember { mutableFloatStateOf(1f) }
    var saturation by remember { mutableFloatStateOf(1f) }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        CenterAlignedTopAppBar(
            title = { Text("Adjust Image") },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
            },
            colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
                navigationIconContentColor = MaterialTheme.colorScheme.onPrimaryContainer
            )
        )

        if (bitmap != null) {
            // Preview
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Image(
                    bitmap = bitmap.asImageBitmap(),
                    contentDescription = "Image to Adjust",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Fit
                )
            }

            // Adjustment controls
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                // Brightness
                Text("Brightness")
                Slider(
                    value = brightness,
                    onValueChange = { brightness = it },
                    valueRange = -1f..1f,
                    steps = 100
                )

                // Contrast
                Text("Contrast")
                Slider(
                    value = contrast,
                    onValueChange = { contrast = it },
                    valueRange = 0f..2f,
                    steps = 100
                )

                // Saturation
                Text("Saturation")
                Slider(
                    value = saturation,
                    onValueChange = { saturation = it },
                    valueRange = 0f..2f,
                    steps = 100
                )

                // Apply button
                Button(
                    onClick = {
                        val adjustedBitmap = applyAdjustments(bitmap, brightness, contrast, saturation)
                        onAdjustComplete(adjustedBitmap)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp)
                ) {
                    Text("Apply Adjustments")
                }
            }
        }
    }
}

private fun applyAdjustments(source: Bitmap, brightness: Float, contrast: Float, saturation: Float): Bitmap {
    val width = source.width
    val height = source.height
    val result = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    
    for (x in 0 until width) {
        for (y in 0 until height) {
            val pixel = source.getPixel(x, y)
            val a = android.graphics.Color.alpha(pixel)
            var r = android.graphics.Color.red(pixel).toFloat()
            var g = android.graphics.Color.green(pixel).toFloat()
            var b = android.graphics.Color.blue(pixel).toFloat()
            
            // Apply brightness
            r += brightness * 255f
            g += brightness * 255f
            b += brightness * 255f
            
            // Apply contrast
            r = (((r - 128f) * contrast) + 128f)
            g = (((g - 128f) * contrast) + 128f)
            b = (((b - 128f) * contrast) + 128f)
            
            // Apply saturation
            val avg = (r + g + b) / 3f
            r = (avg + (r - avg) * saturation)
            g = (avg + (g - avg) * saturation)
            b = (avg + (b - avg) * saturation)
            
            // Clamp values
            val finalR = r.roundToInt().coerceIn(0, 255)
            val finalG = g.roundToInt().coerceIn(0, 255)
            val finalB = b.roundToInt().coerceIn(0, 255)
            
            val newPixel = android.graphics.Color.argb(a, finalR, finalG, finalB)
            result.setPixel(x, y, newPixel)
        }
    }
    return result
}

@Composable
fun ProfileActivity(
    navController: NavController,
    viewModel: ProfileViewModel = viewModel()
) {
    var profileImageUri by remember { mutableStateOf<Uri?>(null) }
    var title by remember { mutableStateOf("") }
    var company by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var about by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // ... existing profile setup UI code ...

        Button(
            onClick = {
                // Update profile with final information
                viewModel.userProfile.value?.let { currentProfile ->
                    viewModel.updateProfile(
                        fullName = currentProfile.fullName,
                        title = title,
                        company = company,
                        education = currentProfile.education,
                        location = location,
                        about = about,
                        profileImage = profileImageUri,
                        coverImage = null // Can be added later
                    )
                }
                // Navigate to final profile page
                navController.navigate("profile") {
                    popUpTo("login") { inclusive = true }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            shape = RoundedCornerShape(24.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2))
        ) {
            Text("Finish and View Profile", color = Color.White)
        }
    }
}

// ... rest of the existing code ... 