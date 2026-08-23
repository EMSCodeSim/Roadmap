import 'package:flutter/foundation.dart';

@immutable
class StateFireAuthority {
  final String stateCode;
  final String sourceTitle;
  final String sourceUrl;
  final String guidance;
  final DateTime verifiedDate;

  const StateFireAuthority({
    required this.stateCode,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.guidance,
    required this.verifiedDate,
  });
}

/// Official state-level fire training/certification authority references.
///
/// This catalog does NOT mean every credential shown by Career Road is a
/// statewide employment mandate. Many states use voluntary certification or
/// allow local departments/AHJs to set hiring and promotional requirements.
/// The authority record gives the user the correct state source to verify the
/// requirement against instead of inheriting another state's rules.
class StateFireAuthorityCatalog {
  const StateFireAuthorityCatalog._();

  static final DateTime _verified = DateTime(2026, 8, 23);

  static final Map<String, StateFireAuthority> _byState = {
    'AL': StateFireAuthority(
      stateCode: 'AL',
      sourceTitle: 'Alabama Fire College & Personnel Standards and Education Commission',
      sourceUrl: 'https://www.alabamafirecollege.org/certification-overview/',
      guidance: 'Alabama maintains statewide firefighter certification standards. Paid and part-paid firefighters have state certification requirements; volunteer pathways differ. Confirm the exact rule for your employment status and department.',
      verifiedDate: _verified,
    ),
    'AK': StateFireAuthority(
      stateCode: 'AK',
      sourceTitle: 'Alaska Fire Standards Council',
      sourceUrl: 'https://dps.alaska.gov/afsc/',
      guidance: 'Alaska operates a statewide fire certification system, but the state describes firefighter certification as voluntary. Departments may require specific levels.',
      verifiedDate: _verified,
    ),
    'AZ': StateFireAuthority(
      stateCode: 'AZ',
      sourceTitle: 'Arizona Office of the State Fire Marshal',
      sourceUrl: 'https://dffm.az.gov/fire-marshals-office',
      guidance: 'Arizona fire-service training and credential expectations are strongly influenced by local departments and recognized certification providers. Confirm the current requirement with the hiring department and state fire-service authority.',
      verifiedDate: _verified,
    ),
    'AR': StateFireAuthority(
      stateCode: 'AR',
      sourceTitle: 'Arkansas Department of Public Safety — Fire Services / Arkansas Fire Training Academy',
      sourceUrl: 'https://dps.arkansas.gov/emergency-management/adem/state-fire-marshals-office/fire-services/',
      guidance: 'Arkansas maintains state fire-service training standards and Act 833 training requirements for participating departments. Certification and annual training expectations depend on department status and role.',
      verifiedDate: _verified,
    ),
    'CA': StateFireAuthority(
      stateCode: 'CA',
      sourceTitle: 'CAL FIRE Office of the State Fire Marshal — State Fire Training',
      sourceUrl: 'https://osfm.fire.ca.gov/what-we-do/state-fire-training',
      guidance: 'California State Fire Training provides the state professional certification pathway. Hiring agencies and departments may set additional or different employment requirements.',
      verifiedDate: _verified,
    ),
    'CO': StateFireAuthority(
      stateCode: 'CO',
      sourceTitle: 'Colorado Division of Fire Prevention and Control — Professional Qualifications and Training',
      sourceUrl: 'https://dfpc.colorado.gov/fire-service-training-and-certification-advisory-board',
      guidance: 'Colorado firefighter certification is a voluntary state program. Individual departments determine which certifications are required for hiring, assignment, and promotion.',
      verifiedDate: _verified,
    ),
    'CT': StateFireAuthority(
      stateCode: 'CT',
      sourceTitle: 'Connecticut Commission on Fire Prevention and Control / Connecticut Fire Academy',
      sourceUrl: 'https://portal.ct.gov/cfpc/certification',
      guidance: 'Connecticut provides professional competency certification through the Commission on Fire Prevention and Control. Hiring and promotional rules may still be department-specific.',
      verifiedDate: _verified,
    ),
    'DE': StateFireAuthority(
      stateCode: 'DE',
      sourceTitle: 'Delaware State Fire School / State Fire Prevention Commission',
      sourceUrl: 'https://statefireschool.delaware.gov/',
      guidance: 'Delaware uses statewide fire-service standards and State Fire School training/certification pathways. Confirm the current Fire Prevention Commission standard for the position you are pursuing.',
      verifiedDate: _verified,
    ),
    'FL': StateFireAuthority(
      stateCode: 'FL',
      sourceTitle: 'Florida Bureau of Fire Standards and Training',
      sourceUrl: 'https://www.myfloridacfo.com/division/sfm/bfst',
      guidance: 'Florida regulates firefighter certification through the Bureau of Fire Standards and Training. Use the current Bureau requirements for initial certification and any specialty or promotional credential.',
      verifiedDate: _verified,
    ),
    'GA': StateFireAuthority(
      stateCode: 'GA',
      sourceTitle: 'Georgia Firefighter Standards and Training Council',
      sourceUrl: 'https://georgia.gov/organization/georgia-firefighter-standards-and-training-council',
      guidance: 'Georgia establishes minimum firefighter standards and state certification rules. Certain full-time positions require state certification; part-time and volunteer classifications have separate minimum training/certification rules.',
      verifiedDate: _verified,
    ),
    'HI': StateFireAuthority(
      stateCode: 'HI',
      sourceTitle: 'Hawaii State Fire Council',
      sourceUrl: 'https://law.hawaii.gov/about-us/state-of-fire-council/',
      guidance: 'Hawaii coordinates statewide fire-service policy through the State Fire Council, while county fire departments control many hiring, training, and advancement requirements. Verify the county department standard.',
      verifiedDate: _verified,
    ),
    'ID': StateFireAuthority(
      stateCode: 'ID',
      sourceTitle: 'Idaho Fire Service Training — Division of Career Technical Education',
      sourceUrl: 'https://cte.idaho.gov/programs-2/fire-service-training/',
      guidance: 'Idaho Fire Service Training provides statewide firefighter training and certification to national standards. Local departments may impose additional hiring or advancement requirements.',
      verifiedDate: _verified,
    ),
    'IL': StateFireAuthority(
      stateCode: 'IL',
      sourceTitle: 'Illinois Office of the State Fire Marshal — Personnel Standards and Education',
      sourceUrl: 'https://sfm.illinois.gov/about/divisions/personnel-standards.html',
      guidance: 'Illinois operates a voluntary state firefighter certification program. Local governments and fire departments decide which certifications they require.',
      verifiedDate: _verified,
    ),
    'IN': StateFireAuthority(
      stateCode: 'IN',
      sourceTitle: 'Indiana Fire and Public Safety Academy',
      sourceUrl: 'https://www.in.gov/dhs/fire-and-building-safety/indiana-fire-and-public-safety-academy/',
      guidance: 'Indiana provides statewide firefighter training and certification through the Fire and Public Safety Academy. Verify current prerequisites and department-specific employment rules.',
      verifiedDate: _verified,
    ),
    'IA': StateFireAuthority(
      stateCode: 'IA',
      sourceTitle: 'Iowa State Fire Marshal — Fire Service Training Bureau',
      sourceUrl: 'https://dps.iowa.gov/divisions/state-fire-marshal/fire-service-training',
      guidance: 'Iowa administers a statewide fire-service certification program. Use the current Fire Service Training Bureau policies for certification prerequisites and testing.',
      verifiedDate: _verified,
    ),
    'KS': StateFireAuthority(
      stateCode: 'KS',
      sourceTitle: 'Kansas Fire & Rescue Training Institute',
      sourceUrl: 'https://fire.ku.edu/',
      guidance: 'The Kansas Fire & Rescue Training Institute is the state fire credentialing institute. Departments may still set their own employment and promotion requirements beyond state certification.',
      verifiedDate: _verified,
    ),
    'KY': StateFireAuthority(
      stateCode: 'KY',
      sourceTitle: 'Kentucky Fire Commission',
      sourceUrl: 'https://kyfirecommission.kctcs.edu/fire_commission_programs/firefighter-certification.aspx',
      guidance: 'Kentucky uses Basic 1 certification for volunteer firefighters and Basic 2 for paid firefighters, with time limits tied to service status. Advanced IFSAC certification pathways are also available.',
      verifiedDate: _verified,
    ),
    'LA': StateFireAuthority(
      stateCode: 'LA',
      sourceTitle: 'Louisiana Fire & Emergency Training Academy',
      sourceUrl: 'https://feta.la.gov/',
      guidance: 'Louisiana FETA provides the statewide certification program, which the Academy describes as voluntary. Departments may require specific certifications for appointment or advancement.',
      verifiedDate: _verified,
    ),
    'ME': StateFireAuthority(
      stateCode: 'ME',
      sourceTitle: 'Maine Fire Service Institute',
      sourceUrl: 'https://mfsi.me.edu/',
      guidance: 'Maine Fire Service Institute provides state fire training and professional certification. State law describes participation in the training program as voluntary; local departments may require credentials.',
      verifiedDate: _verified,
    ),
    'MD': StateFireAuthority(
      stateCode: 'MD',
      sourceTitle: 'Maryland Fire-Rescue Education and Training Commission',
      sourceUrl: 'https://mhec.maryland.gov/institutions_training/Pages/acadaff/mfretc.aspx',
      guidance: 'Maryland coordinates fire, rescue, and EMS education at the state level while local jurisdictions retain major responsibility for personnel requirements. Verify the hiring jurisdiction standard.',
      verifiedDate: _verified,
    ),
    'MA': StateFireAuthority(
      stateCode: 'MA',
      sourceTitle: 'Massachusetts Fire Training Council / Massachusetts Firefighting Academy',
      sourceUrl: 'https://www.mass.gov/info-details/massachusetts-fire-service-certification-system',
      guidance: 'Massachusetts fire-service certification is voluntary statewide, although individual departments may require specific certification levels.',
      verifiedDate: _verified,
    ),
    'MI': StateFireAuthority(
      stateCode: 'MI',
      sourceTitle: 'Michigan Bureau of Fire Services',
      sourceUrl: 'https://www.michigan.gov/lara/bureau-list/bfs',
      guidance: 'Michigan Bureau of Fire Services administers state fire training and certification standards. Confirm current qualification rules for the position and department type.',
      verifiedDate: _verified,
    ),
    'MN': StateFireAuthority(
      stateCode: 'MN',
      sourceTitle: 'Minnesota Board of Firefighter Training and Education',
      sourceUrl: 'https://dps.mn.gov/divisions/sfm/fire-depts/mn-board-firefighter-training-and-education',
      guidance: 'Minnesota uses board-approved firefighter examinations and firefighter licensing. Local departments may impose training requirements beyond the state minimum.',
      verifiedDate: _verified,
    ),
    'MS': StateFireAuthority(
      stateCode: 'MS',
      sourceTitle: 'Mississippi State Fire Academy / Minimum Standards and Certification Board',
      sourceUrl: 'https://msfa.ms.gov/about/',
      guidance: 'Mississippi has mandatory training/certification rules for covered paid fire personnel. The State Fire Academy is the principal statewide training and certification-testing agency.',
      verifiedDate: _verified,
    ),
    'MO': StateFireAuthority(
      stateCode: 'MO',
      sourceTitle: 'Missouri Division of Fire Safety',
      sourceUrl: 'https://dfs.dps.mo.gov/programs/training/',
      guidance: 'Missouri Division of Fire Safety provides statewide accredited fire-service certification programs. Confirm whether the credential is required by the employing department or role.',
      verifiedDate: _verified,
    ),
    'MT': StateFireAuthority(
      stateCode: 'MT',
      sourceTitle: 'Montana Fire Services Training School',
      sourceUrl: 'https://www.montana.edu/extension/fsts/aboutus.html',
      guidance: 'Montana Fire Services Training School is the state-level training agency and provides professional certification testing. Local agencies may establish additional requirements.',
      verifiedDate: _verified,
    ),
    'NE': StateFireAuthority(
      stateCode: 'NE',
      sourceTitle: 'Nebraska State Fire Marshal — Training Division',
      sourceUrl: 'https://sfm.nebraska.gov/training',
      guidance: 'Nebraska State Fire Marshal Training Division is the state certifying authority, but participation in the statewide training/certification program is not mandatory by statute.',
      verifiedDate: _verified,
    ),
    'NV': StateFireAuthority(
      stateCode: 'NV',
      sourceTitle: 'Nevada State Fire Marshal — Training and Certification Bureau',
      sourceUrl: 'https://fire.nv.gov/bureaus/FST/',
      guidance: 'Nevada provides state certification testing for firefighter, hazmat, officer, instructor, and driver/operator levels. Local employer requirements may differ.',
      verifiedDate: _verified,
    ),
    'NH': StateFireAuthority(
      stateCode: 'NH',
      sourceTitle: 'New Hampshire Fire Academy and EMS',
      sourceUrl: 'https://www.nh.gov/safety/divisions/fstems/',
      guidance: 'New Hampshire publishes course and certification prerequisites for firefighter, driver/operator, officer, instructor, and related fire-service levels. Use the current prerequisite guide.',
      verifiedDate: _verified,
    ),
    'NJ': StateFireAuthority(
      stateCode: 'NJ',
      sourceTitle: 'New Jersey Division of Fire Safety — Office of Training and Certification',
      sourceUrl: 'https://www.nj.gov/dca/divisions/dfs/',
      guidance: 'New Jersey administers state firefighter certification and adopted training/exam requirements. Use the current Division of Fire Safety certification criteria.',
      verifiedDate: _verified,
    ),
    'NM': StateFireAuthority(
      stateCode: 'NM',
      sourceTitle: 'New Mexico Firefighters Training Academy / State Fire Marshal',
      sourceUrl: 'https://www.dhsem.nm.gov/state-fire-marshal/fire-training-academy/',
      guidance: 'New Mexico provides statewide accredited certification programs and training intended to support State Fire Marshal training requirements. Confirm the current rule for the department and role.',
      verifiedDate: _verified,
    ),
    'NY': StateFireAuthority(
      stateCode: 'NY',
      sourceTitle: 'New York State Office of Fire Prevention and Control',
      sourceUrl: 'https://www.dhses.ny.gov/new-york-state-certifications',
      guidance: 'New York has specific statutory training/certification requirements for covered career firefighters and first-line supervisors, while volunteer and local requirements can differ.',
      verifiedDate: _verified,
    ),
    'NC': StateFireAuthority(
      stateCode: 'NC',
      sourceTitle: 'North Carolina Office of State Fire Marshal — Fire and Rescue Commission',
      sourceUrl: 'https://www.ncosfm.gov/fire-rescue',
      guidance: 'North Carolina administers statewide fire and rescue certification programs. Local departments may require additional certifications or experience for appointment and promotion.',
      verifiedDate: _verified,
    ),
    'ND': StateFireAuthority(
      stateCode: 'ND',
      sourceTitle: 'North Dakota Firefighter’s Association Certification Program',
      sourceUrl: 'https://apps.nd.gov/NDFA/',
      guidance: 'North Dakota operates a statewide firefighter certification program that is voluntary. Departments may establish certification requirements locally.',
      verifiedDate: _verified,
    ),
    'OH': StateFireAuthority(
      stateCode: 'OH',
      sourceTitle: 'Ohio Department of Public Safety — Division of EMS, Fire Service Education',
      sourceUrl: 'https://ems.ohio.gov/',
      guidance: 'Ohio regulates firefighter training and certification through the Division of EMS. Use current Ohio fire-service certification rules and chartered training requirements.',
      verifiedDate: _verified,
    ),
    'OK': StateFireAuthority(
      stateCode: 'OK',
      sourceTitle: 'Oklahoma State University Fire Service Training',
      sourceUrl: 'https://www.osufst.org/',
      guidance: 'Oklahoma Fire Service Training provides statewide fire-service training and certification support. Employment requirements may be set by the local department or municipality.',
      verifiedDate: _verified,
    ),
    'OR': StateFireAuthority(
      stateCode: 'OR',
      sourceTitle: 'Oregon Department of Public Safety Standards and Training — Fire Certification',
      sourceUrl: 'https://www.oregon.gov/dpsst/FirePrograms/Pages/default.aspx',
      guidance: 'Oregon DPSST fire certification is voluntary statewide and documents professional competence. Departments may require particular levels locally.',
      verifiedDate: _verified,
    ),
    'PA': StateFireAuthority(
      stateCode: 'PA',
      sourceTitle: 'Pennsylvania State Fire Academy / Office of the State Fire Commissioner',
      sourceUrl: 'https://www.pa.gov/agencies/osfc/programs/state-fire-academy.html',
      guidance: 'Pennsylvania provides statewide professional certification through the State Fire Academy. Local departments and municipalities determine many employment requirements.',
      verifiedDate: _verified,
    ),
    'RI': StateFireAuthority(
      stateCode: 'RI',
      sourceTitle: 'Rhode Island State Fire Marshal / Fire Education and Training',
      sourceUrl: 'https://fire-marshal.ri.gov/',
      guidance: 'Rhode Island fire-service training and certification are coordinated at the state level, while local departments may set hiring and promotional prerequisites.',
      verifiedDate: _verified,
    ),
    'SC': StateFireAuthority(
      stateCode: 'SC',
      sourceTitle: 'South Carolina Fire Academy',
      sourceUrl: 'https://statefire.llr.sc.gov/scfa/',
      guidance: 'South Carolina Fire Academy provides statewide training and certification. Confirm current Academy prerequisites and any additional department requirements.',
      verifiedDate: _verified,
    ),
    'SD': StateFireAuthority(
      stateCode: 'SD',
      sourceTitle: 'South Dakota State Fire Marshal — Fire Service Training',
      sourceUrl: 'https://www.sd.gov/dps?id=cs_kb_article_view&sysparm_article=KB0043253',
      guidance: 'South Dakota provides certified firefighter, instructor, driver/operator, and officer training through the State Fire Marshal program. Confirm role-specific local requirements.',
      verifiedDate: _verified,
    ),
    'TN': StateFireAuthority(
      stateCode: 'TN',
      sourceTitle: 'Tennessee Commission on Firefighting Personnel Standards and Education',
      sourceUrl: 'https://www.tn.gov/commerce/firefighting-commission.html',
      guidance: 'Tennessee’s Commission certifies paid and volunteer firefighters and approves programs used to meet the state minimum training statute. Verify the certification level required for the position.',
      verifiedDate: _verified,
    ),
    'TX': StateFireAuthority(
      stateCode: 'TX',
      sourceTitle: 'Texas Commission on Fire Protection',
      sourceUrl: 'https://www.tcfp.texas.gov/services/certifications',
      guidance: 'Texas requires specific TCFP certifications for personnel employed and appointed to regulated fire-protection duties. Other certifications such as driver/operator and fire officer are voluntary statewide unless required locally.',
      verifiedDate: _verified,
    ),
    'UT': StateFireAuthority(
      stateCode: 'UT',
      sourceTitle: 'Utah Fire Service Certification Council / Utah Fire & Rescue Academy',
      sourceUrl: 'https://firemarshal.utah.gov/services/state-boards/fire-service-certification-council/',
      guidance: 'Utah’s Fire Service Certification Council establishes uniform minimum standards for state firefighter certification. Departments may adopt additional requirements.',
      verifiedDate: _verified,
    ),
    'VT': StateFireAuthority(
      stateCode: 'VT',
      sourceTitle: 'Vermont Fire Academy — Division of Fire Safety',
      sourceUrl: 'https://firesafety.vermont.gov/academy',
      guidance: 'Vermont Fire Academy administers state fire-service training and certification. Confirm the current Academy prerequisites and local department requirements.',
      verifiedDate: _verified,
    ),
    'VA': StateFireAuthority(
      stateCode: 'VA',
      sourceTitle: 'Virginia Department of Fire Programs',
      sourceUrl: 'https://www.vafire.com/',
      guidance: 'Virginia Department of Fire Programs administers accredited fire training, testing, and certification. Local departments may set additional qualification requirements.',
      verifiedDate: _verified,
    ),
    'WA': StateFireAuthority(
      stateCode: 'WA',
      sourceTitle: 'Washington State Fire Training Academy — Washington State Patrol',
      sourceUrl: 'https://wsp.wa.gov/fire-training-academy/',
      guidance: 'Washington State Fire Training Academy provides IFSAC-aligned firefighter certification training. Individual departments establish hiring and advancement standards.',
      verifiedDate: _verified,
    ),
    'WV': StateFireAuthority(
      stateCode: 'WV',
      sourceTitle: 'West Virginia State Fire Commission / State Fire Marshal',
      sourceUrl: 'https://firemarshal.wv.gov/Training/Pages/default.aspx',
      guidance: 'West Virginia coordinates statewide firefighter training and certification through the State Fire Commission/State Fire Marshal. Verify the current level required for the role.',
      verifiedDate: _verified,
    ),
    'WI': StateFireAuthority(
      stateCode: 'WI',
      sourceTitle: 'Wisconsin Technical College System — Fire Service Training',
      sourceUrl: 'https://www.wtcsystem.edu/',
      guidance: 'Wisconsin fire-service training and certification are delivered through the Wisconsin Technical College System and local agencies. Confirm the employing department’s certification standard.',
      verifiedDate: _verified,
    ),
    'WY': StateFireAuthority(
      stateCode: 'WY',
      sourceTitle: 'Wyoming State Fire Marshal — Fire Training',
      sourceUrl: 'https://wsfm.wyo.gov/',
      guidance: 'Wyoming fire-service training and certification are coordinated through the State Fire Marshal and local fire agencies. Confirm current state and department requirements.',
      verifiedDate: _verified,
    ),
    'DC': StateFireAuthority(
      stateCode: 'DC',
      sourceTitle: 'District of Columbia Fire and EMS Department — Training Academy',
      sourceUrl: 'https://fems.dc.gov/',
      guidance: 'District of Columbia Fire and EMS Department controls recruit, operational, and promotional training requirements for its personnel. Use current FEMS hiring and academy requirements.',
      verifiedDate: _verified,
    ),
  };

  static StateFireAuthority? forState(String? stateCode) {
    final code = stateCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) return null;
    return _byState[code];
  }

  static bool hasAuthorityForState(String? stateCode) =>
      forState(stateCode) != null;

  static List<StateFireAuthority> get all =>
      _byState.values.toList(growable: false);
}
