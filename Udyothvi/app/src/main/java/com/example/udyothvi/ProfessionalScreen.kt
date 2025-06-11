package com.example.udyothvi

import android.widget.Toast
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfessionalScreen(
    onAddMore: () -> Unit,
    onBack: () -> Unit,
    onSaveAndContinue: () -> Unit,
    onSkip: () -> Unit,
    viewModel: ProfessionalViewModel = viewModel()
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }
    var editingIndex by remember { mutableStateOf<Int?>(null) }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
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
                text = "Professional Experience",
                    style = MaterialTheme.typography.headlineMedium,
                    modifier = Modifier.padding(start = 8.dp)
            )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Form for new experience
            OutlinedTextField(
                value = viewModel.title.value,
                onValueChange = { viewModel.title.value = it },
                label = { Text("Job Title") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
            )

            OutlinedTextField(
                value = viewModel.company.value,
                onValueChange = { viewModel.company.value = it },
                label = { Text("Company") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
            )

            OutlinedTextField(
                value = viewModel.startDate.value,
                onValueChange = { viewModel.startDate.value = it },
                label = { Text("Start Date") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp),
                readOnly = true,
                trailingIcon = {
                    IconButton(onClick = { showStartDatePicker = true }) {
                        Icon(
                            imageVector = Icons.Default.DateRange,
                            contentDescription = "Select Start Date"
                        )
                    }
                }
            )

            OutlinedTextField(
                value = viewModel.endDate.value,
                onValueChange = { viewModel.endDate.value = it },
                label = { Text("End Date") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                readOnly = true,
                trailingIcon = {
                    IconButton(onClick = { showEndDatePicker = true }) {
                        Icon(
                            imageVector = Icons.Default.DateRange,
                            contentDescription = "Select End Date"
                        )
                    }
                }
            )

            OutlinedTextField(
                value = viewModel.description.value,
                onValueChange = { viewModel.description.value = it },
                label = { Text("Description") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp)
                    .height(120.dp),
                maxLines = 5
            )

            // Add More Button
            OutlinedButton(
                onClick = {
                    if (viewModel.title.value.isNotBlank() &&
                        viewModel.company.value.isNotBlank() &&
                        viewModel.startDate.value.isNotBlank() &&
                        viewModel.endDate.value.isNotBlank()
                    ) {
                        if (editingIndex != null) {
                            viewModel.updateExperience(editingIndex!!)
                            editingIndex = null
                        } else {
                            viewModel.addExperience()
                        }
                        onAddMore()
                    } else {
                        Toast.makeText(context, "Please fill all fields", Toast.LENGTH_SHORT).show()
                    }
                },
                modifier = Modifier
                    .padding(vertical = 16.dp)
                    .align(Alignment.Start),
                border = BorderStroke(1.dp, Color(0xFF8A2BE2)),
                shape = RoundedCornerShape(24.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add More",
                        tint = Color(0xFF8A2BE2)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "Add More",
                        color = Color(0xFF8A2BE2)
                    )
                }
            }

            // Display previously added experiences
            if (viewModel.experiences.isNotEmpty()) {
                Text(
                    text = "Previous Experiences",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
                Column {
                viewModel.experiences.forEachIndexed { index, experience ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFFF5F5F5))
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(
                                modifier = Modifier.weight(1f)
                            ) {
                                    Text(
                                        text = experience.title,
                                        style = MaterialTheme.typography.titleMedium
                                    )
                                    Text(text = experience.company)
                                    Text(text = "${experience.startDate} - ${experience.endDate}")
                                    Text(text = experience.description)
                            }
                            Row {
                                IconButton(onClick = {
                                    viewModel.editExperience(index)
                                    editingIndex = index
                                }) {
                                        Icon(Icons.Default.Edit, "Edit", tint = Color.Blue)
                                }
                                IconButton(onClick = {
                                    viewModel.deleteExperience(index)
                                    if (editingIndex == index) {
                                        viewModel.clearForm()
                                        editingIndex = null
                                    }
                                }) {
                                        Icon(Icons.Default.Delete, "Delete", tint = Color.Red)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom navigation
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
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
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                contentAlignment = Alignment.CenterEnd
            ) {
                TextButton(onClick = onSkip) {
                    Text("Skip", color = Color(0xFF8A2BE2))
                }
            }
        }
    }

    if (showStartDatePicker) {
        CustomDatePickerDialog(
            onDateSelected = { date ->
                viewModel.startDate.value = SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(date)
                showStartDatePicker = false
            },
            onDismiss = { showStartDatePicker = false },
            title = "Select Start Date"
        )
    }

    if (showEndDatePicker) {
        CustomDatePickerDialog(
            onDateSelected = { date ->
                viewModel.endDate.value = SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(date)
                showEndDatePicker = false
            },
            onDismiss = { showEndDatePicker = false },
            title = "Select End Date"
        )
    }
}