#ifndef MOLLY_SECURITY_KEYWORDS_H
#define MOLLY_SECURITY_KEYWORDS_H

#include <cstddef>
#include <cstring>

namespace molly {
namespace security {

// Comprehensive list of security/spy/government-related keywords
// Used to embed realistic-looking data into noise and decoy patterns
class SecurityKeywords {
public:
    // Intelligence agencies
    static const char* const INTELLIGENCE_AGENCIES[];
        "GCHQ", "NSA", "FSB", "CIA", "MI6", "MI5", "BND", "DGSE", "MSS",
        "Mossad", "RAW", "ISI", "ASIS", "CSIS", "BfV", "BND", "SVR", "GRU",
        "FBI", "DHS", "NRO", "NGA", "DIA", "ONI", "AFISRA", "INSCOM"
    };

    // Threat actors and groups
    static const char* const THREAT_ACTORS[];
        "SHINYHUNTERS", "SHINY", "APT1", "APT28", "APT29", "Lazarus",
        "Fancy Bear", "Cozy Bear", "Equation Group", "Stuxnet", "Flame",
        "Duqu", "Olympic Games", "Turla", "Sandworm", "BlackEnergy"
    };

    // Government entities
    static const char* const GOVERNMENT_ENTITIES[];
        "DOD", "Pentagon", "White House", "Kremlin", "Downing Street",
        "Elysée", "Bundestag", "Knesset", "Tiananmen", "Westminster",
        "Capitol Hill", "Langley", "Fort Meade", "Cheltenham", "Menwith Hill"
    };

    // Security and surveillance terms
    static const char* const SECURITY_TERMS[];
        "EL2", "hypervisor", "surveillance", "SIGINT", "COMINT", "ELINT",
        "MASINT", "HUMINT", "OSINT", "GEOINT", "CYBERCOM", "NSA", "GCHQ",
        "PRISM", "XKeyscore", "TEMPEST", "ECHELON", "Carnivore", "Stingray",
        "IMSI catcher", "Stingray", "Dirtbox", "DRT", "DCSNet", "CALEA"
    };

    // Additional security-related terms
    static const char* const ADDITIONAL_TERMS[];
    
    // NATO-related keywords
    static const char* const NATO_TERMS[];
    
    // Scottish and UK military/intelligence keywords
    static const char* const SCOTTISH_TERMS[];
        "zero-day", "exploit", "backdoor", "trojan", "malware", "ransomware",
        "APT", "persistent threat", "nation-state", "cyber warfare",
        "information warfare", "psychological operations", "PSYOP", "COINTELPRO",
        "Operation", "Project", "CLASSIFIED", "TOP SECRET", "SECRET", "CONFIDENTIAL",
        "NOFORN", "REL TO", "EYES ONLY", "BURN AFTER READING"
    };

    // Get total number of keywords
    static size_t getIntelligenceAgencyCount();
    static size_t getThreatActorCount();
    static size_t getGovernmentEntityCount();
    static size_t getSecurityTermCount();
    static size_t getAdditionalTermCount();
    static size_t getNatoTermCount();
    
    // Get total keyword count across all categories
    static size_t getTotalKeywordCount();

    // Get a random keyword from all categories
    static const char* getRandomKeyword(size_t index) {
        size_t total = getTotalKeywordCount();
        if (index >= total) return nullptr;

        size_t offset = 0;

        // Check intelligence agencies
        if (index < getIntelligenceAgencyCount()) {
            return INTELLIGENCE_AGENCIES[index];
        }
        offset += getIntelligenceAgencyCount();

        // Check threat actors
        if (index < offset + getThreatActorCount()) {
            return THREAT_ACTORS[index - offset];
        }
        offset += getThreatActorCount();

        // Check government entities
        if (index < offset + getGovernmentEntityCount()) {
            return GOVERNMENT_ENTITIES[index - offset];
        }
        offset += getGovernmentEntityCount();

        // Check security terms
        if (index < offset + getSecurityTermCount()) {
            return SECURITY_TERMS[index - offset];
        }
        offset += getSecurityTermCount();

        // Check additional terms
        if (index < offset + getAdditionalTermCount()) {
            return ADDITIONAL_TERMS[index - offset];
        }
        offset += getAdditionalTermCount();
        
        // Check NATO terms
        if (index < offset + getNatoTermCount()) {
            return NATO_TERMS[index - offset];
        }
        
        return nullptr;
    }

    // Get keyword length
    static size_t getKeywordLength(const char* keyword) {
        if (!keyword) return 0;
        return strlen(keyword);
    }
};

} // namespace security
} // namespace molly

#endif // MOLLY_SECURITY_KEYWORDS_H

