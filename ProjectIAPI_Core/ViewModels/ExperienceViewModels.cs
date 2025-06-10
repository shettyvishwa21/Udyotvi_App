using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ProjectIAPI_Core.ViewModels
{
    public class ExperienceUpsert
    {
        [Required]
        public long UserId { get; set; }

        [Required]
        public List<ExperienceData> ExperienceData { get; set; }
    }

    public class ExperienceData
    {
        public int experience_id { get; set; } // 0 for insert, >0 for update

        [Required]
        public string organisation_name { get; set; }

        [Required]
        public string designation { get; set; }

        public bool currently_pursuing { get; set; }

        [Required]
        public DateTime? start_date { get; set; }

        public DateTime? end_date { get; set; }
    }

    public class UpsertExperienceResult
    {
        public int ResultType { get; set; }
        public string ResultMessage { get; set; }
        public long UserId { get; set; }
    }
}