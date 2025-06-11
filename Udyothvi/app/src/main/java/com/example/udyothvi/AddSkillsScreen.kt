package com.example.udyothvi

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.lifecycle.viewmodel.compose.viewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddSkillsScreen(
    navController: NavController,
    onComplete: () -> Unit,
    viewModel: ProfileViewModel = viewModel()
) {
    var skillInput by remember { mutableStateOf("") }
    var skills by remember { mutableStateOf(listOf<String>()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Add Your Skills",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 24.dp)
        )

        // Skill Input
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = skillInput,
                onValueChange = { skillInput = it },
                label = { Text("Enter a skill") },
                modifier = Modifier
                    .weight(1f)
                    .padding(end = 8.dp),
                singleLine = true
            )

            IconButton(
                onClick = {
                    if (skillInput.isNotEmpty()) {
                        skills = skills + skillInput
                        skillInput = ""
                    }
                },
                modifier = Modifier.size(48.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Skill")
            }
        }

        // Skills List
        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
        ) {
            items(skills) { skill ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(skill)
                        IconButton(
                            onClick = { skills = skills - skill }
                        ) {
                            Icon(Icons.Default.Close, contentDescription = "Remove Skill")
                        }
                    }
                }
            }
        }

        // Next Button
        Button(
            onClick = {
                viewModel.userProfile.value?.let { currentProfile ->
                    viewModel.updateProfile(
                        fullName = currentProfile.fullName,
                        title = currentProfile.title,
                        company = currentProfile.company,
                        education = currentProfile.education,
                        location = currentProfile.location,
                        about = currentProfile.about,
                        skills = skills,
                        profileImage = currentProfile.profileImage,
                        coverImage = currentProfile.coverImage
                    )
                }
                onComplete()
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            shape = RoundedCornerShape(24.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2))
        ) {
            Text("Next", color = Color.White)
        }
    }
} 