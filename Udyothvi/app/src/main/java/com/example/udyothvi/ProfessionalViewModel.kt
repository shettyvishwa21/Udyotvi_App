package com.example.udyothvi

import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import com.example.udyothvi.model.Experience

class ProfessionalViewModel : ViewModel() {
    // List of added experiences
    val experiences = mutableStateListOf<Experience>()

    // Current form state
    val title = mutableStateOf("")
    val company = mutableStateOf("")
    val startDate = mutableStateOf("")
    val endDate = mutableStateOf("")
    val description = mutableStateOf("")

    // Add a new experience and reset the form
    fun addExperience() {
        val experience = Experience(
            title = title.value,
            company = company.value,
            startDate = startDate.value,
            endDate = endDate.value,
            description = description.value
        )
        experiences.add(experience)
        // Reset form
        clearForm()
    }

    // Update an existing experience
    fun updateExperience(index: Int) {
        if (index < experiences.size) {
            val updatedExperience = Experience(
                title = title.value,
                company = company.value,
                startDate = startDate.value,
                endDate = endDate.value,
                description = description.value
            )
            experiences[index] = updatedExperience
            // Reset form after updating
            clearForm()
        }
    }

    // Populate form with an existing experience for editing
    fun editExperience(index: Int) {
        if (index < experiences.size) {
            val experience = experiences[index]
            title.value = experience.title
            company.value = experience.company
            startDate.value = experience.startDate
            endDate.value = experience.endDate
            description.value = experience.description
        }
    }

    // Delete an experience
    fun deleteExperience(index: Int) {
        if (index < experiences.size) {
            experiences.removeAt(index)
        }
    }

    // Clear form
    fun clearForm() {
        title.value = ""
        company.value = ""
        startDate.value = ""
        endDate.value = ""
        description.value = ""
    }
}