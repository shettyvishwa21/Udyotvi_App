using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ProjectIAPI_Core.ViewModels
{
    public class EducationUpsert
    {
        [Required]
        public long UserId { get; set; }

        [Required]
        public List<EducationData> EducationData { get; set; }
    }

    public class EducationData
    {
        public int education_id { get; set; } // 0 for insert, >0 for update

        [Required]
        public string education_level { get; set; }

        [Required]
        public string organisation_name { get; set; }

        public bool currentlyPursuing { get; set; }

        [Required]
        public DateTime? start_date { get; set; }

        public DateTime? end_date { get; set; }
    }




    public class UpsertEducationResult
    {
        public int ResultType { get; set; }
        public string ResultMessage { get; set; }
        public long UserId { get; set; }
    }
}