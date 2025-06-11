package com.example.udyothvi

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Crop
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.FilterAlt
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.FileUpload
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.navigation.NavController
import com.canhub.cropper.CropImageContract
import com.canhub.cropper.CropImageContractOptions
import com.canhub.cropper.CropImageOptions
import com.canhub.cropper.CropImageView
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

enum class EditMode {
    NONE, CROP, FILTER, ADJUST
}

data class ImageFilter(
    val name: String,
    val matrix: ColorMatrix
)

val imageFilters = listOf(
    ImageFilter("Normal", ColorMatrix().apply { setToSaturation(1f) }),
    ImageFilter("Grayscale", ColorMatrix().apply { setToSaturation(0f) }),
    ImageFilter("Sepia", ColorMatrix(floatArrayOf(
            1.3f, -0.3f, 1.1f, 0f, 0f,
            0f, 1.3f, 0.2f, 0f, 0f,
            0f, 0f, 0.8f, 0.2f, 0f,
            0f, 0f, 0f, 1f, 0f
    ))),
    ImageFilter("Vintage", ColorMatrix(floatArrayOf(
            0.9f, 0.5f, 0.1f, 0f, 0f,
            0.3f, 0.8f, 0.1f, 0f, 0f,
            0.2f, 0.3f, 0.5f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
    ))),
    ImageFilter("Cool", ColorMatrix(floatArrayOf(
            1f, 0f, 0f, 0f, 0f,
            0f, 1f, 0.1f, 0f, 0f,
            0f, 0f, 1.2f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
    ))),
    ImageFilter("Warm", ColorMatrix(floatArrayOf(
            1.2f, 0f, 0f, 0f, 0f,
            0f, 1.1f, 0f, 0f, 0f,
            0f, 0f, 0.9f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
    )))
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SkillsAndMediaPage(navController: NavController) {
    val context = LocalContext.current
    var skillInput by remember { mutableStateOf(TextFieldValue("")) }
    val skills = remember { mutableStateListOf<String>() }

    var selectedImageUri by remember { mutableStateOf<Uri?>(null) }
    var selectedCertUri by remember { mutableStateOf<Uri?>(null) }
    var showEditDialog by remember { mutableStateOf(false) }
    var currentEditMode by remember { mutableStateOf(EditMode.NONE) }
    var currentBitmap by remember { mutableStateOf<Bitmap?>(null) }

    var selectedFilter by remember { mutableStateOf(imageFilters[0]) }
    var brightness by remember { mutableFloatStateOf(1f) }
    var contrast by remember { mutableFloatStateOf(1f) }
    var saturation by remember { mutableFloatStateOf(1f) }

    // Add new state variables for edited images
    var filteredBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var adjustedBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var croppedBitmap by remember { mutableStateOf<Bitmap?>(null) }

    // Add a state to track the saved image filename
    var savedImageFilename by remember { mutableStateOf<String?>(null) }
    var imageCounter by remember { mutableStateOf(1) }

    // Add a state to track the uploaded document filename
    var uploadedDocFilename by remember { mutableStateOf<String?>(null) }

    val cropImage = rememberLauncherForActivityResult(CropImageContract()) { result ->
        when {
            result.isSuccessful -> {
                result.uriContent?.let { uri ->
                    try {
                        val inputStream = context.contentResolver.openInputStream(uri)
                        currentBitmap = BitmapFactory.decodeStream(inputStream)
                        // Save the cropped image
                        currentBitmap?.let { bitmap ->
                            saveImage(context, bitmap, "skill_image.jpg")
                            Toast.makeText(context, "Image cropped and saved successfully", Toast.LENGTH_SHORT).show()
                        }
                        showEditDialog = true
                        currentEditMode = EditMode.NONE
                    } catch (e: Exception) {
                        Toast.makeText(context, "Failed to save cropped image", Toast.LENGTH_SHORT).show()
                        e.printStackTrace()
                    }
                }
            }
            result.uriContent == null && result.error == null -> {
                // Handle cancellation
                Toast.makeText(context, "Image cropping cancelled", Toast.LENGTH_SHORT).show()
                showEditDialog = true
                currentEditMode = EditMode.NONE
            }
            else -> {
                val error = result.error
                Toast.makeText(context, "Image cropping failed: ${error?.message}", Toast.LENGTH_SHORT).show()
                showEditDialog = true
                currentEditMode = EditMode.NONE
            }
        }
    }

    val imagePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri -> 
        uri?.let {
            selectedImageUri = it
            try {
                val inputStream = context.contentResolver.openInputStream(it)
                currentBitmap = BitmapFactory.decodeStream(inputStream)
                currentEditMode = EditMode.NONE
                showEditDialog = true
            } catch (e: Exception) {
                Toast.makeText(context, "Failed to load image", Toast.LENGTH_SHORT).show()
            }
        }
    }

    val certPicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri -> 
        uri?.let {
            selectedCertUri = it
            // Save the filename
            val name = it.lastPathSegment?.substringAfterLast('/') ?: "document.pdf"
            uploadedDocFilename = name
            Toast.makeText(context, "Document uploaded successfully.", Toast.LENGTH_SHORT).show()
        }
    }

    val primaryColor = Color(0xFF6200EE)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Back Arrow
            IconButton(
                onClick = { navController.navigateUp() },
                modifier = Modifier.align(Alignment.Start)
            ) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = "Back",
                    tint = primaryColor
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                "Add Skills",
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.padding(bottom = 24.dp)
            )

            // Skill input section
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = skillInput,
                    onValueChange = { skillInput = it },
                    label = { Text("Enter a skill") },
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions.Default.copy(imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = {
                        if (skillInput.text.isNotBlank()) {
                            skills.add(skillInput.text.trim())
                            skillInput = TextFieldValue("")
                        }
                    }),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = primaryColor,
                        unfocusedBorderColor = Color.Gray
                    )
                )
                Button(
                    onClick = {
                        if (skillInput.text.isNotBlank()) {
                            skills.add(skillInput.text.trim())
                            skillInput = TextFieldValue("")
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2)),
                    shape = RoundedCornerShape(24.dp)
                ) {
                    Text("Add")
                }
            }

            // Skills list
            if (skills.isNotEmpty()) {
                Text(
                    "Your Skills",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(vertical = 16.dp)
                )
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp)
                ) {
                    items(skills.size) { index ->
                        Card(
                            modifier = Modifier.clickable { skills.removeAt(index) },
                            shape = RoundedCornerShape(50.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = Color(0xFFE8E0FF),
                                contentColor = primaryColor
                            ),
                            border = BorderStroke(1.dp, primaryColor)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                            ) {
                                Text(skills[index])
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("✕", color = Color.Red)
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Upload section
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Uploaded files section
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp)
                ) {
                    // Show uploaded image filename if available
                    if (savedImageFilename != null) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp)
            ) {
                            Icon(
                                imageVector = Icons.Default.Image,
                                contentDescription = "Image",
                                tint = primaryColor,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                "Image: $savedImageFilename",
                                modifier = Modifier.weight(1f),
                                color = Color.Black
                            )
                            IconButton(onClick = {
                                val file = File(context.filesDir, "skill_images/${savedImageFilename!!}")
                                if (file.exists()) file.delete()
                                savedImageFilename = null
                            }) {
                                Icon(Icons.Default.Close, contentDescription = "Delete", tint = Color.Red)
                            }
                        }
                    }

                    // Show uploaded document filename if available
                    if (uploadedDocFilename != null) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.FileUpload,
                                contentDescription = "Document",
                                tint = primaryColor,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                "Document: $uploadedDocFilename",
                                modifier = Modifier.weight(1f),
                                color = Color.Black
                            )
                            IconButton(onClick = {
                                val file = File(context.filesDir, "skill_docs/$uploadedDocFilename")
                                if (file.exists()) file.delete()
                                uploadedDocFilename = null
                            }) {
                                Icon(Icons.Default.Close, contentDescription = "Delete", tint = Color.Red)
                            }
                        }
                    }
                }

                // Upload buttons
                OutlinedButton(
                    onClick = { imagePicker.launch("image/*") },
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = primaryColor
                    ),
                    border = BorderStroke(1.dp, primaryColor),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Default.Image,
                        contentDescription = "Upload Skill Image",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Upload Skill Image")
                }

                OutlinedButton(
                    onClick = { 
                        try {
                            certPicker.launch(arrayOf("application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                        } catch (e: Exception) {
                            Toast.makeText(context, "Failed to open document picker", Toast.LENGTH_SHORT).show()
                        }
                    },
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = primaryColor
                    ),
                    border = BorderStroke(1.dp, primaryColor),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Default.FileUpload,
                        contentDescription = "Upload Certification",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Upload Certification")
                }
            }

            // Bottom navigation
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                    .padding(16.dp)
            ) {
                // Centered Save & Next button
                    Row(
                        modifier = Modifier
                        .fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                    ) {
                    Button(
                            onClick = {
                            if (skills.isNotEmpty()) {
                                navController.navigate("professionalScreen") {
                                    popUpTo("skillsAndMediaPage") { inclusive = true }
                                }
                            } else {
                                Toast.makeText(context, "Please add at least one skill", Toast.LENGTH_SHORT).show()
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2)),
                        shape = RoundedCornerShape(24.dp),
                        modifier = Modifier.width(200.dp)
                        ) {
                        Text("Save & Next")
                        }
                }

                // Skip button on the right
                Row(
                            modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .clickable { 
                            navController.navigate("professionalScreen") {
                                popUpTo("skillsAndMediaPage") { inclusive = true }
                            }
                        },
                    verticalAlignment = Alignment.CenterVertically
                        ) {
                    Text(
                        text = "Skip",
                        color = Color(0xFF8A2BE2)
                    )
                            Icon(
                        Icons.Default.ArrowForward,
                        contentDescription = "Skip",
                        tint = Color(0xFF8A2BE2),
                        modifier = Modifier.padding(start = 4.dp)
                            )
                }
            }
        }
    }

    // Edit options dialog
    if (showEditDialog && currentBitmap != null) {
        Dialog(onDismissRequest = { showEditDialog = false }) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = Color.Black
            ) {
                when (currentEditMode) {
                    EditMode.NONE -> {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            // Image preview
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .weight(1f),
                                contentAlignment = Alignment.Center
                            ) {
                                    Image(
                                    bitmap = currentBitmap!!.asImageBitmap(),
                                    contentDescription = "Edited Image",
                                        modifier = Modifier.fillMaxSize(),
                                        contentScale = ContentScale.Fit
                                    )
                                }
                            Spacer(modifier = Modifier.height(16.dp))
                            // Edit options
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceEvenly
                            ) {
                                Button(onClick = { currentEditMode = EditMode.CROP }) { Text("Crop") }
                                Button(onClick = { currentEditMode = EditMode.FILTER }) { Text("Filter") }
                                Button(onClick = { currentEditMode = EditMode.ADJUST }) { Text("Adjust") }
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            // Save Final Image button
                            Button(
                                onClick = {
                                    try {
                                        val filename = "image${imageCounter}.jpg"
                                        saveImage(context, currentBitmap!!, filename)
                                        savedImageFilename = filename
                                        imageCounter += 1
                                        Toast.makeText(context, "Final image saved!", Toast.LENGTH_SHORT).show()
                                        showEditDialog = false
                                    } catch (e: Exception) {
                                        Toast.makeText(context, "Failed to save image", Toast.LENGTH_SHORT).show()
                                    }
                                },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Save Final Image")
                            }
                        }
                    }
                    EditMode.FILTER -> {
                        Column(
                            modifier = Modifier.fillMaxSize()
                        ) {
                            // Top bar
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                IconButton(onClick = { 
                                    currentEditMode = EditMode.NONE
                                    filteredBitmap = null
                                }) {
                                    Icon(
                                        Icons.Default.ArrowBack,
                                        contentDescription = "Back",
                                        tint = Color.White
                                    )
                                }
                                Text(
                                    "Filters",
                                    color = Color.White,
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Row {
                                    TextButton(
                                        onClick = {
                                            currentEditMode = EditMode.NONE
                                            filteredBitmap = null
                                        }
                                    ) {
                                        Text("Cancel", color = Color.White)
                                    }
                                TextButton(
                                    onClick = {
                                        currentBitmap?.let { bitmap ->
                                            try {
                                                    // Apply the selected filter to the bitmap
                                                    val filtered = applyFilterToBitmap(bitmap, selectedFilter.matrix)
                                                    currentBitmap = filtered
                                                    filteredBitmap = null
                                                    saveImage(context, filtered, "skill_image.jpg")
                                                Toast.makeText(context, "Image saved successfully", Toast.LENGTH_SHORT).show()
                                                currentEditMode = EditMode.NONE
                                            } catch (e: Exception) {
                                                Toast.makeText(context, "Failed to save image", Toast.LENGTH_SHORT).show()
                                                e.printStackTrace()
                                            }
                                        }
                                    }
                                ) {
                                    Text("Save", color = Color.White)
                                    }
                                }
                            }

                            // Image preview with selected filter
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxWidth()
                            ) {
                                currentBitmap?.let { bitmap ->
                                    Image(
                                        bitmap = bitmap.asImageBitmap(),
                                        contentDescription = "Selected Image",
                                        modifier = Modifier.fillMaxSize(),
                                        contentScale = ContentScale.Fit,
                                        colorFilter = ColorFilter.colorMatrix(selectedFilter.matrix)
                                    )
                                }
                            }

                            // Filter options
                            LazyRow(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 16.dp),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                contentPadding = PaddingValues(horizontal = 16.dp)
                            ) {
                                items(imageFilters) { filter ->
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        modifier = Modifier
                                            .width(80.dp)
                                            .clickable { selectedFilter = filter }
                                            .border(
                                                width = 2.dp,
                                                color = if (selectedFilter == filter) Color(0xFF6200EE) else Color.Transparent,
                                                shape = RoundedCornerShape(8.dp)
                                            )
                                            .padding(8.dp)
                                    ) {
                                        currentBitmap?.let { bitmap ->
                                            Image(
                                                bitmap = bitmap.asImageBitmap(),
                                                contentDescription = filter.name,
                                                modifier = Modifier
                                                    .size(60.dp)
                                                    .clip(RoundedCornerShape(4.dp)),
                                                contentScale = ContentScale.Crop,
                                                colorFilter = ColorFilter.colorMatrix(filter.matrix)
                                            )
                                        }
                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(
                                            filter.name,
                                            color = Color.White,
                                            style = MaterialTheme.typography.bodySmall
                                        )
                                    }
                                }
                            }
                        }
                    }
                    EditMode.ADJUST -> {
                        Column(
                            modifier = Modifier.fillMaxSize()
                        ) {
                            // Top bar
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                IconButton(onClick = { 
                                    currentEditMode = EditMode.NONE
                                    adjustedBitmap = null
                                }) {
                                    Icon(
                                        Icons.Default.ArrowBack,
                                        contentDescription = "Back",
                                        tint = Color.White
                                    )
                                }
                                Text(
                                    "Adjust",
                                    color = Color.White,
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Row {
                                    TextButton(
                                        onClick = {
                                            currentEditMode = EditMode.NONE
                                            adjustedBitmap = null
                                        }
                                    ) {
                                        Text("Cancel", color = Color.White)
                                    }
                                TextButton(
                                    onClick = {
                                        currentBitmap?.let { bitmap ->
                                            try {
                                                    // Apply the adjustments to the bitmap
                                                    val adjusted = applyAdjustmentsToBitmap(bitmap, brightness, contrast, saturation)
                                                    currentBitmap = adjusted
                                                    adjustedBitmap = null
                                                    saveImage(context, adjusted, "skill_image.jpg")
                                                Toast.makeText(context, "Image saved successfully", Toast.LENGTH_SHORT).show()
                                                currentEditMode = EditMode.NONE
                                            } catch (e: Exception) {
                                                Toast.makeText(context, "Failed to save image", Toast.LENGTH_SHORT).show()
                                                e.printStackTrace()
                                            }
                                        }
                                    }
                                ) {
                                    Text("Save", color = Color.White)
                                    }
                                }
                            }

                            // Image preview
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxWidth()
                            ) {
                                currentBitmap?.let { bitmap ->
                                    // Create a single matrix that combines all adjustments
                                    val combinedMatrix = ColorMatrix(floatArrayOf(
                                        // Red channel
                                        contrast * brightness, 0f, 0f, 0f, 0f,
                                        // Green channel
                                        0f, contrast * brightness, 0f, 0f, 0f,
                                        // Blue channel
                                        0f, 0f, contrast * brightness, 0f, 0f,
                                        // Alpha channel
                                        0f, 0f, 0f, 1f, 0f
                                    )).apply {
                                        // Apply saturation
                                        setToSaturation(saturation)
                                    }
                                    
                                    Image(
                                        bitmap = bitmap.asImageBitmap(),
                                        contentDescription = "Selected Image",
                                        modifier = Modifier.fillMaxSize(),
                                        contentScale = ContentScale.Fit,
                                        colorFilter = ColorFilter.colorMatrix(combinedMatrix)
                                    )
                                }
                            }

                            // Adjustment controls
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp)
                            ) {
                                // Brightness control
                                Text(
                                    "Brightness",
                                    color = Color.White,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                Slider(
                                    value = brightness,
                                    onValueChange = { brightness = it },
                                    valueRange = 0.5f..1.5f,
                                    colors = SliderDefaults.colors(
                                        thumbColor = Color(0xFF6200EE),
                                        activeTrackColor = Color(0xFF6200EE),
                                        inactiveTrackColor = Color.DarkGray
                                    )
                                )
                                Spacer(modifier = Modifier.height(16.dp))

                                // Contrast control
                                Text(
                                    "Contrast",
                                    color = Color.White,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                Slider(
                                    value = contrast,
                                    onValueChange = { contrast = it },
                                    valueRange = 0.5f..1.5f,
                                    colors = SliderDefaults.colors(
                                        thumbColor = Color(0xFF6200EE),
                                        activeTrackColor = Color(0xFF6200EE),
                                        inactiveTrackColor = Color.DarkGray
                                    )
                                )
                                Spacer(modifier = Modifier.height(16.dp))

                                // Saturation control
                                Text(
                                    "Saturation",
                                    color = Color.White,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                Slider(
                                    value = saturation,
                                    onValueChange = { saturation = it },
                                    valueRange = 0f..2f,
                                    colors = SliderDefaults.colors(
                                        thumbColor = Color(0xFF6200EE),
                                        activeTrackColor = Color(0xFF6200EE),
                                        inactiveTrackColor = Color.DarkGray
                                    )
                                )
                            }
                        }
                    }
                    EditMode.CROP -> {
                        Column(
                            modifier = Modifier.fillMaxSize()
                        ) {
                            // Top bar
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                IconButton(
                                    onClick = { 
                                        currentEditMode = EditMode.NONE
                                        croppedBitmap = null
                                    }
                                ) {
                                    Icon(
                                        Icons.Default.ArrowBack,
                                        contentDescription = "Back",
                                        tint = Color.White
                                    )
                                }
                                Text(
                                    "Crop",
                                    color = Color.White,
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Row {
                                    TextButton(
                                        onClick = {
                                            currentEditMode = EditMode.NONE
                                            croppedBitmap = null
                                        }
                                    ) {
                                        Text("Cancel", color = Color.White)
                                    }
                                TextButton(
                                    onClick = {
                                        selectedImageUri?.let { uri ->
                                            val cropOptions = CropImageContractOptions(
                                                uri,
                                                CropImageOptions().apply {
                                                    guidelines = CropImageView.Guidelines.ON
                                                    cropShape = CropImageView.CropShape.RECTANGLE
                                                    showCropOverlay = true
                                                    autoZoomEnabled = true
                                                    fixAspectRatio = false
                                                    
                                                    // Basic styling
                                                    backgroundColor = android.graphics.Color.rgb(33, 33, 33)
                                                    borderLineColor = android.graphics.Color.WHITE
                                                    borderLineThickness = 3f
                                                    guidelinesColor = android.graphics.Color.rgb(158, 158, 158)
                                                    guidelinesThickness = 1f
                                                    
                                                    // Activity styling
                                                    activityMenuIconColor = android.graphics.Color.WHITE
                                                    activityBackgroundColor = android.graphics.Color.rgb(33, 33, 33)
                                                    activityTitle = "Crop Image"
                                                    toolbarColor = android.graphics.Color.rgb(98, 0, 238)
                                                    
                                                    // Button customization
                                                    cropMenuCropButtonTitle = "Save"
                                                    
                                                    // Show progress
                                                    showProgressBar = true
                                                }
                                            )
                                            cropImage.launch(cropOptions)
                                        }
                                    }
                                ) {
                                    Text("Save", color = Color.White)
                                    }
                                }
                            }

                            // Image preview
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxWidth()
                            ) {
                                currentBitmap?.let { bitmap ->
                                    Image(
                                        bitmap = bitmap.asImageBitmap(),
                                        contentDescription = "Selected Image",
                                        modifier = Modifier.fillMaxSize(),
                                        contentScale = ContentScale.Fit
                                    )
                                }
                            }

                            // Bottom crop controls
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                horizontalArrangement = Arrangement.SpaceEvenly
                            ) {
                                // Cancel button
                                Button(
                                    onClick = { currentEditMode = EditMode.NONE },
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = Color(0xFF2A2A2A)
                                    ),
                                    modifier = Modifier.weight(1f).padding(end = 8.dp)
                                ) {
                                    Text("Cancel", color = Color.White)
                                }
                                
                                // Save button
                                Button(
                                    onClick = {
                                        selectedImageUri?.let { uri ->
                                            val cropOptions = CropImageContractOptions(
                                                uri,
                                                CropImageOptions().apply {
                                                    guidelines = CropImageView.Guidelines.ON
                                                    cropShape = CropImageView.CropShape.RECTANGLE
                                                    showCropOverlay = true
                                                    autoZoomEnabled = true
                                                    fixAspectRatio = false
                                                }
                                            )
                                            cropImage.launch(cropOptions)
                                        }
                                    },
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = Color(0xFF6200EE)
                                    ),
                                    modifier = Modifier.weight(1f).padding(start = 8.dp)
                                ) {
                                    Text("Save", color = Color.White)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun EditOption(
    icon: ImageVector,
    text: String,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        color = Color.Transparent
    ) {
        Row(
            modifier = Modifier
                .padding(vertical = 12.dp, horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = text,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text(text, style = MaterialTheme.typography.bodyLarge)
        }
    }
}

private fun saveImage(context: Context, bitmap: Bitmap, filename: String) {
    try {
        val imagesDir = File(context.filesDir, "skill_images").apply {
            if (!exists()) mkdirs()
        }
        val file = File(imagesDir, filename)
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
        }
    } catch (e: Exception) {
        e.printStackTrace()
        throw e
    }
}

// Function to apply filter to bitmap
fun applyFilterToBitmap(bitmap: Bitmap, matrix: ColorMatrix): Bitmap {
    val width = bitmap.width
    val height = bitmap.height
    val result = Bitmap.createBitmap(width, height, bitmap.config ?: Bitmap.Config.ARGB_8888)
    val canvas = android.graphics.Canvas(result)
    val paint = android.graphics.Paint().apply {
        colorFilter = android.graphics.ColorMatrixColorFilter(matrix.values)
    }
    canvas.drawBitmap(bitmap, 0f, 0f, paint)
    return result
}

// Function to apply adjustments to bitmap
fun applyAdjustmentsToBitmap(bitmap: Bitmap, brightness: Float, contrast: Float, saturation: Float): Bitmap {
    val width = bitmap.width
    val height = bitmap.height
    val bmp = Bitmap.createBitmap(width, height, bitmap.config ?: Bitmap.Config.ARGB_8888)
    val canvas = android.graphics.Canvas(bmp)
    val paint = android.graphics.Paint()
    val cm = android.graphics.ColorMatrix()
    // Saturation
    cm.setSaturation(saturation)
    // Contrast
    val scale = contrast
    val translate = (-.5f * scale + .5f) * 255f
    val contrastArray = floatArrayOf(
        scale, 0f, 0f, 0f, translate,
        0f, scale, 0f, 0f, translate,
        0f, 0f, scale, 0f, translate,
        0f, 0f, 0f, 1f, 0f
    )
    cm.postConcat(android.graphics.ColorMatrix(contrastArray))
    // Brightness
    val brightnessArray = floatArrayOf(
        brightness, 0f, 0f, 0f, 0f,
        0f, brightness, 0f, 0f, 0f,
        0f, 0f, brightness, 0f, 0f,
        0f, 0f, 0f, 1f, 0f
    )
    cm.postConcat(android.graphics.ColorMatrix(brightnessArray))
    paint.colorFilter = android.graphics.ColorMatrixColorFilter(cm)
    canvas.drawBitmap(bitmap, 0f, 0f, paint)
    return bmp
}