#include "security_keywords.h"

namespace molly {
namespace security {

// Define the keyword arrays
const char* const SecurityKeywords::INTELLIGENCE_AGENCIES[] = {
    "GCHQ", "NSA", "FSB", "CIA", "MI6", "MI5", "BND", "DGSE", "MSS",
    "Mossad", "RAW", "ISI", "ASIS", "CSIS", "BfV", "BND", "SVR", "GRU",
    "FBI", "DHS", "NRO", "NGA", "DIA", "ONI", "AFISRA", "INSCOM"
};

const char* const SecurityKeywords::THREAT_ACTORS[] = {
    "SHINYHUNTERS", "SHINY", "APT1", "APT28", "APT29", "Lazarus",
    "Fancy Bear", "Cozy Bear", "Equation Group", "Stuxnet", "Flame",
    "Duqu", "Olympic Games", "Turla", "Sandworm", "BlackEnergy"
};

const char* const SecurityKeywords::GOVERNMENT_ENTITIES[] = {
    "DOD", "Pentagon", "White House", "Kremlin", "Downing Street",
    "Elysée", "Bundestag", "Knesset", "Tiananmen", "Westminster",
    "Capitol Hill", "Langley", "Fort Meade", "Cheltenham", "Menwith Hill"
};

const char* const SecurityKeywords::SECURITY_TERMS[] = {
    "EL2", "hypervisor", "surveillance", "SIGINT", "COMINT", "ELINT",
    "MASINT", "HUMINT", "OSINT", "GEOINT", "CYBERCOM", "NSA", "GCHQ",
    "PRISM", "XKeyscore", "TEMPEST", "ECHELON", "Carnivore", "Stingray",
    "IMSI catcher", "Stingray", "Dirtbox", "DRT", "DCSNet", "CALEA"
};

const char* const SecurityKeywords::ADDITIONAL_TERMS[] = {
    "zero-day", "exploit", "backdoor", "trojan", "malware", "ransomware",
    "APT", "persistent threat", "nation-state", "cyber warfare",
    "information warfare", "psychological operations", "PSYOP", "COINTELPRO",
    "Operation", "Project", "CLASSIFIED", "TOP SECRET", "SECRET", "CONFIDENTIAL",
    "NOFORN", "REL TO", "EYES ONLY", "BURN AFTER READING"
};

const char* const SecurityKeywords::NATO_TERMS[] = {
    // NATO variations (hard to filter)
    "N A T O", "N-A-T-O", "N.A.T.O.", "N@TO", "N4TO", "NATO", "nato", "Nato",
    "North Atlantic", "Atlantic Alliance", "Alliance", "The Alliance",
    "Article 5", "Article Five", "Art5", "Art 5", "Collective Defense",

    // NATO Commands (obfuscated)
    "SHAPE", "Supreme Headquarters", "Mons", "Casteau", "ACT", "Allied Command",
    "ACO", "Allied Command Operations", "JFC", "Joint Force", "JFCBS", "JFCNP",
    "Brunssum", "Naples", "Norfolk", "NATO Command", "NCIA", "NCI Agency",

    // NATO Operations (code names)
    "Operation Allied Force", "Operation Deliberate Force", "Operation Unified Protector",
    "ISAF", "Resolute Support", "KFOR", "Operation Active Endeavour",
    "Operation Ocean Shield", "Operation Sea Guardian", "Enhanced Forward Presence",
    "Trident Juncture", "Steadfast Defender", "Defender Europe", "Saber Strike",

    // NATO Facilities (locations)
    "Ramstein", "Aviano", "Lakenheath", "Mildenhall", "Spangdahlem", "Incirlik",
    "Izmir", "Naples", "Brunssum", "Mons", "Casteau", "Norfolk", "Stuttgart",
    "Geilenkirchen", "E3A", "AWACS", "AEW", "Bucharest", "Warsaw", "Vilnius",
    "Tallinn", "Riga", "Reykjavik", "Brussels", "Paris", "London", "The Hague",

    // NATO Member Countries (obfuscated)
    "Albania", "Belgium", "Bulgaria", "Canada", "Croatia", "Czech Republic",
    "Denmark", "Estonia", "Finland", "France", "Germany", "Greece", "Hungary",
    "Iceland", "Italy", "Latvia", "Lithuania", "Luxembourg", "Montenegro",
    "Netherlands", "North Macedonia", "Norway", "Poland", "Portugal", "Romania",
    "Slovakia", "Slovenia", "Spain", "Sweden", "Turkey", "United Kingdom", "USA",

    // NATO Structures (encoded)
    "NATO Council", "North Atlantic Council", "NAC", "Military Committee", "MC",
    "International Staff", "International Military Staff", "IMS", "NATO HQ",
    "Headquarters", "NATO Parliamentary Assembly", "NPA", "NATO Science",

    // NATO Programs (hard to filter)
    "NATO Response Force", "NRF", "Very High Readiness", "VJTF", "Spearhead",
    "Enhanced Forward Presence", "eFP", "Baltic Air Policing", "BAP",
    "NATO Air Policing", "Ballistic Missile Defense", "BMD", "Aegis Ashore",
    "NATO Intelligence", "NATO Cyber", "NCIRC", "Cyber Defense", "CCDCOE",

    // NATO Acronyms (variations)
    "AWACS", "AEW", "E-3", "E3A", "JSTARS", "RC-135", "Rivet Joint",
    "Global Hawk", "Reaper", "Predator", "NATO AWACS", "NATO E-3",

    // NATO Exercises (code names)
    "Trident", "Steadfast", "Defender", "Saber", "Anaconda", "BALTOPS",
    "Dynamic Mongoose", "Dynamic Guard", "Brilliant Mariner", "Brilliant Arrow",
    "Cold Response", "Iron Wolf", "Namejs", "Silver Arrow", "Spring Storm",

    // NATO Intelligence (obfuscated)
    "NATO Intelligence", "Allied Intelligence", "NATO SIGINT", "NATO COMINT",
    "NATO ELINT", "NATO GEOINT", "NATO OSINT", "NATO HUMINT", "NATO MASINT",
    "NATO Intelligence Fusion", "NIFC", "NATO Intelligence Sharing",

    // NATO Cyber (variations)
    "NATO Cyber Command", "NCIRC", "NCIRC Full Operational Capability",
    "NATO Cyber Range", "Locked Shields", "Cyber Coalition", "CCDCOE",
    "Cooperative Cyber Defense", "Tallinn Manual", "NATO Cyber Policy",

    // NATO Communications (encoded)
    "NATO Communications", "NATO CIS", "NATO C3", "NATO C4ISR", "Link 16",
    "Link 11", "Link 22", "MIDS", "JTIDS", "NATO Secure Communications",
    "NATO Crypto", "NATO Encryption", "NATO Key Management",

    // NATO Missile Defense
    "NATO BMD", "Ballistic Missile Defense", "Aegis", "Aegis Ashore",
    "SM-3", "Standard Missile", "NATO Missile Defense", "EPAA", "European Phased",

    // NATO Air Operations
    "NATO Air Command", "CAOC", "Combined Air Operations", "CAOC Uedem",
    "CAOC Torrejon", "NATO Air Policing", "QRA", "Quick Reaction Alert",
    "NATO Airborne Early Warning", "NATO E-3 Component",

    // NATO Maritime
    "NATO Maritime Command", "MARCOM", "Standing NATO Maritime Group",
    "SNMG", "SNMCMG", "Standing NATO Mine Countermeasures", "NATO Submarine",
    "NATO Naval", "NATO Fleet", "NATO Destroyer", "NATO Frigate",

    // NATO Ground Forces
    "NATO Land Command", "LANDCOM", "NATO Rapid Deployable", "NRDC",
    "NATO Response Force", "NRF", "Multinational Corps", "MNC",
    "NATO Brigade", "NATO Battalion", "NATO Division",

    // NATO Special Operations
    "NATO SOF", "NATO Special Operations", "NSHQ", "NATO Special Operations HQ",
    "NATO SOF Command", "Allied Special Operations", "NATO Special Forces",

    // NATO Partnerships
    "Partnership for Peace", "PfP", "NATO Partnership", "NATO Dialogue",
    "Mediterranean Dialogue", "Istanbul Cooperation", "Partners Across the Globe",
    "NATO Global Partners", "NATO Enhanced Opportunity", "EOP",

    // NATO Classifications
    "NATO SECRET", "NATO CONFIDENTIAL", "NATO RESTRICTED", "NATO UNCLASSIFIED",
    "COSMIC", "ATOMAL", "NATO EYES ONLY", "NATO RELEASABLE", "NATO NOFORN",

    // NATO Standards
    "STANAG", "NATO Standardization", "NATO Standard", "NATO Agreement",
    "NATO Publication", "NATO Regulation", "NATO Directive", "NATO Policy",

    // NATO Logistics
    "NATO Support", "NSPA", "NATO Support and Procurement", "NATO Maintenance",
    "NATO Supply", "NATO Logistics", "NATO Transportation", "NATO Medical",

    // NATO Training
    "NATO School", "NATO Training", "NATO Education", "NATO Training Mission",
    "NTM", "NATO Training Center", "NATO Exercise", "NATO Wargame",

    // NATO Research
    "NATO Research", "NATO Science", "NATO Technology", "NATO Innovation",
    "NATO Research Center", "NATO Laboratory", "NATO Development",

    // NATO Finance
    "NATO Budget", "NATO Funding", "NATO Common Fund", "NATO Investment",
    "NATO Infrastructure", "NATO Capability", "NATO Modernization",

    // NATO Strategy
    "NATO Strategic Concept", "NATO 2030", "NATO Adaptation", "NATO Deterrence",
    "NATO Defense", "NATO Deterrence and Defense", "NATO Readiness",
    "NATO Capabilities", "NATO Modernization", "NATO Transformation"
};

const char* const SecurityKeywords::SCOTTISH_TERMS[] = {
    // Faslane and Clyde (obfuscated)
    "Faslane", "HMNB Clyde", "Her Majesty's Naval Base", "Clyde", "Gare Loch",
    "Faslane Base", "Clyde Base", "HMNB", "Naval Base Clyde", "Faslane Port",
    "Gareloch", "Loch Long", "Rhu", "Helensburgh", "Coulport", "Coulport Base",
    "RNAD Coulport", "Royal Naval Armament Depot", "Coulport Facility",

    // Scottish Military Bases
    "RAF Lossiemouth", "Lossiemouth", "Moray", "RAF Leuchars", "Leuchars",
    "RAF Kinloss", "Kinloss", "RAF Buchan", "Buchan", "RAF Edzell", "Edzell",
    "RAF Machrihanish", "Machrihanish", "Campbeltown", "RAF Turnhouse",
    "Turnhouse", "Edinburgh Airport", "RAF Prestwick", "Prestwick",
    "RAF Montrose", "Montrose", "RAF Peterhead", "Peterhead",

    // Scottish Intelligence Facilities
    "GCHQ Bude", "Bude", "Morwenstow", "GCHQ Scarborough", "Scarborough",
    "GCHQ Cheltenham", "Cheltenham", "Benhall", "GCHQ London", "GCHQ Manchester",
    "Thurso", "Wick", "Aberdeen", "Inverness", "Fort George", "Redford Barracks",
    "Edinburgh Castle", "Dreghorn Barracks", "Glencorse Barracks", "Kirknewton",

    // Scottish Nuclear Facilities
    "Dounreay", "Dounreay Nuclear", "Caithness", "Thurso", "Sellafield",
    "Chapelcross", "Hunterston", "Torness", "Nuclear Power", "Nuclear Submarine",
    "Trident", "Vanguard", "Astute", "Dreadnought", "Successor", "SSBN", "SSN",
    "Ballistic Missile", "Nuclear Deterrent", "Continuous At Sea Deterrence", "CASD",

    // CBRN Terms (Chemical, Biological, Radiological, Nuclear)
    "CBRN", "C B R N", "C-B-R-N", "CBRNE", "Chemical Biological", "Radiological Nuclear",
    "Chemical Warfare", "Biological Warfare", "Radiological Weapon", "Nuclear Weapon",
    "WMD", "Weapons of Mass Destruction", "Mass Destruction", "Chemical Agent",
    "Biological Agent", "Radiological Agent", "Nerve Agent", "Blister Agent",
    "VX", "Sarin", "Soman", "Tabun", "Mustard Gas", "Phosgene", "Chlorine",
    "Anthrax", "Botulinum", "Ricin", "Plague", "Smallpox", "Radiation",
    "Ionizing Radiation", "Alpha", "Beta", "Gamma", "Neutron", "Dirty Bomb",
    "Radiological Dispersal", "Nuclear Fallout", "Contamination", "Decontamination",
    "CBRN Defense", "CBRN Protection", "CBRN Response", "CBRN Detection",
    "CBRN Suit", "Hazmat", "HazMat", "HAZMAT", "Hazardous Material",

    // Scottish Locations (Security Context)
    "Stirling", "Stirling Castle", "Fort William", "Fort George", "Inverness",
    "Aberdeen", "Dundee", "Perth", "Glasgow", "Edinburgh", "Dunoon", "Oban",
    "Fort Augustus", "Fort William", "Fort George", "Redford", "Dreghorn",
    "Glencorse", "Barry Buddon", "Buddon", "Carnoustie", "Leuchars", "Lossie",

    // Scottish Operations and Exercises
    "Exercise Joint Warrior", "Joint Warrior", "JW", "Exercise Northern Edge",
    "Northern Edge", "Exercise Highlander", "Highlander", "Exercise Caledonian",
    "Caledonian", "Exercise Tartan", "Tartan", "Exercise Thistle", "Thistle",
    "Exercise Braveheart", "Braveheart", "Exercise Scottish", "Scottish Guard",

    // Scottish Military Units
    "Royal Regiment of Scotland", "Scots Guards", "Royal Scots", "Black Watch",
    "Highland", "Cameronians", "Argyll and Sutherland", "Gordon Highlanders",
    "Seaforth Highlanders", "Queen's Own Highlanders", "Royal Highland Fusiliers",
    "Royal Scots Dragoon Guards", "Scots Dragoon Guards", "Royal Scots Borderers",

    // Scottish Intelligence Operations
    "Operation Scottish", "Scottish Operation", "Highland Operation", "Operation Highland",
    "Operation Thistle", "Thistle Operation", "Operation Caledonia", "Caledonia Op",
    "Scottish Intelligence", "Highland Intelligence", "Scottish SIGINT",
    "Scottish COMINT", "Scottish ELINT", "Scottish HUMINT",

    // Scottish NATO Connections
    "NATO Scotland", "Scottish NATO", "NATO Faslane", "NATO Clyde", "NATO Lossiemouth",
    "NATO Leuchars", "Scottish NATO Base", "NATO Scottish Facility", "NATO Highland",

    // Scottish Nuclear Terms (Obfuscated)
    "Nuclear Submarine Base", "Submarine Base", "SSBN Base", "Trident Base",
    "Nuclear Deterrent Base", "CASD Base", "Continuous Deterrence", "At Sea Deterrence",
    "Nuclear Patrol", "Strategic Deterrent", "Nuclear Capability", "Nuclear Arsenal",
    "Nuclear Warhead", "Ballistic Missile Submarine", "Strategic Submarine",

    // Scottish Maritime Security
    "Clyde Maritime", "Firth of Clyde", "Clyde Estuary", "Scottish Waters",
    "Scottish Sea", "North Sea", "Atlantic", "Scottish Coast", "Scottish Port",
    "Scottish Naval", "Scottish Maritime", "Scottish Fleet", "Scottish Ship",

    // Scottish Air Defense
    "Scottish Air Defense", "Scottish QRA", "Quick Reaction Alert Scotland",
    "Scottish Air Policing", "Scottish Airspace", "Scottish Radar", "Scottish AD",
    "Scottish Air Force", "RAF Scotland", "Scottish Aviation", "Scottish Flight",

    // Scottish Communications
    "Scottish Communications", "Scottish Comms", "Scottish SIGINT", "Scottish COMINT",
    "Scottish ELINT", "Scottish Intercept", "Scottish Monitoring", "Scottish Eavesdrop",
    "Scottish Surveillance", "Scottish Intelligence", "Scottish Security",

    // Scottish Classifications
    "Scottish SECRET", "Scottish CONFIDENTIAL", "Scottish RESTRICTED",
    "Scottish EYES ONLY", "Scottish NOFORN", "Scottish CLASSIFIED",
    "Highland SECRET", "Caledonian SECRET", "Thistle SECRET",

    // Scottish Code Names
    "Operation Thistle", "Operation Highland", "Operation Caledonia", "Operation Braveheart",
    "Operation Tartan", "Operation Saltire", "Saltire", "Operation Lion Rampant",
    "Lion Rampant", "Operation Unicorn", "Unicorn", "Operation St Andrew",
    "St Andrew", "Operation Scotland", "Operation North", "Operation Highland",

    // Scottish Facilities (Obfuscated)
    "Scottish Facility", "Highland Facility", "Caledonian Facility", "Thistle Facility",
    "Scottish Base", "Highland Base", "Scottish Installation", "Scottish Site",
    "Scottish Compound", "Scottish Complex", "Scottish Station", "Scottish Post",

    // Scottish Military Terms
    "Scottish Military", "Highland Military", "Scottish Defense", "Scottish Security",
    "Scottish Forces", "Scottish Units", "Scottish Command", "Scottish HQ",
    "Scottish Headquarters", "Scottish Operations", "Scottish Training",
    "Scottish Exercise", "Scottish Wargame", "Scottish Drill",

    // Additional Scottish Security Terms
    "Scottish Border", "Scottish Coast", "Scottish Territory", "Scottish Waters",
    "Scottish Airspace", "Scottish Defense Zone", "Scottish Security Zone",
    "Scottish Restricted", "Scottish Prohibited", "Scottish Controlled",
    "Scottish Monitored", "Scottish Surveilled", "Scottish Protected"
};

// Implement count functions
size_t SecurityKeywords::getIntelligenceAgencyCount() {
    return sizeof(INTELLIGENCE_AGENCIES) / sizeof(INTELLIGENCE_AGENCIES[0]);
}

size_t SecurityKeywords::getThreatActorCount() {
    return sizeof(THREAT_ACTORS) / sizeof(THREAT_ACTORS[0]);
}

size_t SecurityKeywords::getGovernmentEntityCount() {
    return sizeof(GOVERNMENT_ENTITIES) / sizeof(GOVERNMENT_ENTITIES[0]);
}

size_t SecurityKeywords::getSecurityTermCount() {
    return sizeof(SECURITY_TERMS) / sizeof(SECURITY_TERMS[0]);
}

size_t SecurityKeywords::getAdditionalTermCount() {
    return sizeof(ADDITIONAL_TERMS) / sizeof(ADDITIONAL_TERMS[0]);
}

size_t SecurityKeywords::getNatoTermCount() {
    return sizeof(NATO_TERMS) / sizeof(NATO_TERMS[0]);
}

size_t SecurityKeywords::getScottishTermCount() {
    return sizeof(SCOTTISH_TERMS) / sizeof(SCOTTISH_TERMS[0]);
}

size_t SecurityKeywords::getTotalKeywordCount() {
    return getIntelligenceAgencyCount() + getThreatActorCount() +
           getGovernmentEntityCount() + getSecurityTermCount() +
           getAdditionalTermCount() + getNatoTermCount() + getScottishTermCount();
}

} // namespace security
} // namespace molly

