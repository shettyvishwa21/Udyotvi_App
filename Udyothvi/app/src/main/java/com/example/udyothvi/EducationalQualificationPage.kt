package com.example.udyothvi

import android.app.DatePickerDialog
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import java.text.SimpleDateFormat
import java.util.*
import androidx.compose.ui.window.Dialog
import androidx.compose.foundation.border
import androidx.lifecycle.viewmodel.compose.viewModel

data class Education(
    val qualification: String,
    val school: String,
    val fieldOfStudy: String,
    val startDate: String,
    val endDate: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatePickerDialog(
    onDateSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val calendar = Calendar.getInstance()
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = calendar.timeInMillis
    )

    Dialog(onDismissRequest = onDismiss) {
        Card {
            Column {
                DatePicker(
                    state = datePickerState,
                    modifier = Modifier.padding(16.dp)
                )
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(onClick = onDismiss) {
                        Text("Cancel")
                    }
                    TextButton(onClick = {
                        datePickerState.selectedDateMillis?.let { millis ->
                            val date = Date(millis)
                            val formatter = SimpleDateFormat("dd MMM yyyy", Locale.getDefault())
                            onDateSelected(formatter.format(date))
                        }
                        onDismiss()
                    }) {
                        Text("OK")
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EducationalQualificationPageUI(navController: NavController) {
    val context = LocalContext.current
    val sharedPreferences = context.getSharedPreferences("UdyothviPrefs", Context.MODE_PRIVATE)
    val dateFormatter = SimpleDateFormat("dd MMM yyyy", Locale.getDefault())

    var educationList by remember { mutableStateOf(listOf<Education>()) }
    var qualification by remember { mutableStateOf("") }
    var school by remember { mutableStateOf("") }
    var fieldOfStudy by remember { mutableStateOf("") }
    var startDate by remember { mutableStateOf("") }
    var endDate by remember { mutableStateOf("") }
    var showQualificationDropdown by remember { mutableStateOf(false) }
    var showSchoolDropdown by remember { mutableStateOf(false) }
    var showFieldDropdown by remember { mutableStateOf(false) }
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    var editingIndex by remember { mutableStateOf<Int?>(null) }

    val qualificationOptions = listOf(
        "Bachelor of Science (BSc)",
        "Bachelor of Computer Applications (BCA)",
        "Bachelor of Engineering (BE)",
        "Bachelor of Arts (BA)",
        "Bachelor of Commerce (BCom)",
        "Master of Science (MSc)",
        "Master of Computer Applications (MCA)",
        "Master of Business Administration (MBA)",
        "Master of Technology (MTech)",
        "Doctor of Philosophy (PhD)"
    )

    val schoolOptions = listOf(
        "NITTE University",
        "MGM College",
        "PPC College",
        "St. Aloysius College",
        "Manipal Institute of Technology",
        "RV College of Engineering",
        "Christ University",
        "Bangalore University",
        "VTU Belgaum",
        "PES University"
    )

    val fieldOptions = listOf(
        "Computer Science",
        "Information Technology",
        "Physics",
        "Biotechnology",
        "Mathematics",
        "Chemistry",
        "Computer Applications",
        "Electronics",
        "Mechanical Engineering",
        "Civil Engineering"
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(16.dp)
                .verticalScroll(rememberScrollState())
        ) {
            Text(
                text = "Educational Qualification",
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.padding(bottom = 24.dp)
            )

            // Qualification Dropdown
            Text("Educational Qualification", style = MaterialTheme.typography.bodyLarge)
            ExposedDropdownMenuBox(
                expanded = showQualificationDropdown,
                onExpandedChange = { showQualificationDropdown = !showQualificationDropdown }
            ) {
                OutlinedTextField(
                    value = qualification,
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = showQualificationDropdown) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    placeholder = { Text("Select your qualification") },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color.Gray,
                        unfocusedBorderColor = Color.Gray
                    )
                )
                ExposedDropdownMenu(
                    expanded = showQualificationDropdown,
                    onDismissRequest = { showQualificationDropdown = false }
                ) {
                    qualificationOptions.forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option) },
                            onClick = {
                                qualification = option
                                showQualificationDropdown = false
                            }
                        )
                    }
                }
            }

            // School/University Dropdown
            Text("School / University", style = MaterialTheme.typography.bodyLarge, 
                 modifier = Modifier.padding(top = 16.dp))
            ExposedDropdownMenuBox(
                expanded = showSchoolDropdown,
                onExpandedChange = { showSchoolDropdown = !showSchoolDropdown }
            ) {
                OutlinedTextField(
                    value = school,
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = showSchoolDropdown) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    placeholder = { Text("Select your school or university") },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color.Gray,
                        unfocusedBorderColor = Color.Gray
                    )
                )
                ExposedDropdownMenu(
                    expanded = showSchoolDropdown,
                    onDismissRequest = { showSchoolDropdown = false }
                ) {
                    schoolOptions.forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option) },
                            onClick = {
                                school = option
                                showSchoolDropdown = false
                            }
                        )
                    }
                }
            }

            // Field of Study Dropdown
            Text("Field of Study", style = MaterialTheme.typography.bodyLarge,
                 modifier = Modifier.padding(top = 16.dp))
            ExposedDropdownMenuBox(
                expanded = showFieldDropdown,
                onExpandedChange = { showFieldDropdown = !showFieldDropdown }
            ) {
                OutlinedTextField(
                    value = fieldOfStudy,
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = showFieldDropdown) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    placeholder = { Text("Select your field of study") },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color.Gray,
                        unfocusedBorderColor = Color.Gray
                    )
                )
                ExposedDropdownMenu(
                    expanded = showFieldDropdown,
                    onDismissRequest = { showFieldDropdown = false }
                ) {
                    fieldOptions.forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option) },
                            onClick = {
                                fieldOfStudy = option
                                showFieldDropdown = false
                            }
                        )
                    }
                }
            }

            // Duration Fields
            Text("Duration", style = MaterialTheme.typography.bodyLarge,
                 modifier = Modifier.padding(top = 16.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                OutlinedTextField(
                    value = startDate,
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier
                        .weight(1f)
                        .padding(end = 8.dp),
                    placeholder = { Text("Start Date") },
                    trailingIcon = {
                        IconButton(onClick = { showStartDatePicker = true }) {
                            Icon(
                                imageVector = Icons.Default.DateRange,
                                contentDescription = "Select Start Date"
                            )
                        }
                    },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color.Gray,
                        unfocusedBorderColor = Color.Gray
                    )
                )
                OutlinedTextField(
                    value = endDate,
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier
                        .weight(1f)
                        .padding(start = 8.dp),
                    placeholder = { Text("End Date") },
                    trailingIcon = {
                        IconButton(onClick = { showEndDatePicker = true }) {
                            Icon(
                                imageVector = Icons.Default.DateRange,
                                contentDescription = "Select End Date"
                            )
                        }
                    },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color.Gray,
                        unfocusedBorderColor = Color.Gray
                    )
                )
            }

            // Add More Button
            OutlinedButton(
                onClick = {
                    if (qualification.isNotEmpty() && school.isNotEmpty() && fieldOfStudy.isNotEmpty() && startDate.isNotEmpty() && endDate.isNotEmpty()) {
                        val education = Education(qualification, school, fieldOfStudy, startDate, endDate)
                        educationList = educationList + education
                        // Clear fields after adding
                        qualification = ""
                        school = ""
                        fieldOfStudy = ""
                        startDate = ""
                        endDate = ""
                    } else {
                        Toast.makeText(context, "Please fill all fields", Toast.LENGTH_SHORT).show()
                    }
                },
                modifier = Modifier
                    .padding(vertical = 16.dp)
                    .align(Alignment.Start),
                border = BorderStroke(1.dp, Color(0xFF6200EE))
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Add More",
                        tint = Color(0xFF6200EE)
                )
                    Spacer(modifier = Modifier.width(8.dp))
                Text(
                    "Add More",
                        color = Color(0xFF6200EE)
                )
                }
            }

            // Display added qualifications
            if (educationList.isNotEmpty()) {
                Text(
                    "Added Qualifications:",
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.padding(vertical = 16.dp)
                )
                educationList.forEachIndexed { index, education ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFF5F5F5))
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    education.qualification,
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Row {
                                    IconButton(onClick = {
                                        editingIndex = index
                                        qualification = education.qualification
                                        school = education.school
                                        fieldOfStudy = education.fieldOfStudy
                                        startDate = education.startDate
                                        endDate = education.endDate
                                    }) {
                                        Icon(Icons.Default.Edit, "Edit", tint = Color.Blue)
                                    }
                                    IconButton(onClick = {
                                        educationList = educationList.toMutableList().apply { removeAt(index) }
                                    }) {
                                        Icon(Icons.Default.Delete, "Delete", tint = Color.Red)
                                    }
                                }
                            }
                            Text(education.school)
                            Text(education.fieldOfStudy)
                            Text("${education.startDate} - ${education.endDate}")
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom navigation with centered Save & Next and Skip on right
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
                    if (educationList.isNotEmpty()) {
                        navController.navigate("skillsAndMediaPage") {
                            popUpTo("educationalQualification") { inclusive = true }
                        }
                    } else {
                        Toast.makeText(context, "Please add at least one qualification", Toast.LENGTH_SHORT).show()
                    }
                },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2)),
                        shape = RoundedCornerShape(24.dp),
                        modifier = Modifier.width(200.dp)
            ) {
                Text("Save & Next")
            }
                }

                // Skip button at bottom right with proper spacing
                Row(
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(start = 16.dp, bottom = 8.dp)
                        .clickable { 
                    navController.navigate("skillsAndMediaPage") {
                        popUpTo("educationalQualification") { inclusive = true }
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

    // Date pickers
    if (showStartDatePicker) {
        CustomDatePickerDialog(
            onDismiss = { showStartDatePicker = false },
            onDateSelected = { millis -> 
                startDate = dateFormatter.format(Date(millis))
                showStartDatePicker = false
            },
            title = "Select Start Date"
        )
    }

    if (showEndDatePicker) {
        CustomDatePickerDialog(
            onDismiss = { showEndDatePicker = false },
            onDateSelected = { millis ->
                if (startDate.isNotEmpty()) {
                    val startTimestamp = dateFormatter.parse(startDate)?.time ?: 0L
                    if (millis < startTimestamp) {
                        Toast.makeText(context, "End date cannot be before start date", Toast.LENGTH_SHORT).show()
                        return@CustomDatePickerDialog
                    }
                }
                endDate = dateFormatter.format(Date(millis))
                showEndDatePicker = false
            },
            title = "Select End Date"
        )
    }
}

@Composable
fun EducationalQualificationPage(
    navController: NavController,
    onComplete: () -> Unit,
    viewModel: ProfileViewModel = viewModel()
) {
    var qualification by remember { mutableStateOf("") }
    var institute by remember { mutableStateOf("") }
    var startDate by remember { mutableStateOf("") }
    var endDate by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // ... existing educational qualification form UI code ...

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Button(
                onClick = {
                    // Skip button - navigate to profile setup
                    onComplete()
                },
                modifier = Modifier
                    .weight(1f)
                    .padding(end = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.Gray)
            ) {
                Text("Skip")
            }

            Button(
                onClick = {
                    // Update profile with education info
                    viewModel.userProfile.value?.let { currentProfile ->
                        viewModel.updateProfile(
                            fullName = currentProfile.fullName,
                            title = currentProfile.title,
                            company = currentProfile.company,
                            education = "$qualification at $institute ($startDate - $endDate)",
                            location = currentProfile.location,
                            about = currentProfile.about,
                            profileImage = currentProfile.profileImage,
                            coverImage = currentProfile.coverImage
                        )
                    }
                    onComplete()
                },
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2))
            ) {
                Text("Save & Next")
            }
        }
    }
}
