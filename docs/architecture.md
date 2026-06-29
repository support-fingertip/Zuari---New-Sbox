# Zuari — Salesforce Org High-Level Architecture

*Audience: Architect / Tech Lead. Purpose: a single-page mental model of what this org is, what objects it uses, and what flows are designed on top of them.*

---

## 1. What this org does

A **real-estate sales & operations CRM** built on Salesforce. It manages the full funnel from inquiry → site visit → quote → booking → payments → handover, plus a Channel Partner (broker) network, a customer portal, and document generation. The system is integrated with mCube (CTI / omnichannel), WhatsApp, SMS gateways, Marketing Cloud, and an external PDF service.

**Volume signals from the codebase:** 59 custom objects, 28 Apex triggers, 19 major trigger-handler classes, ~150 Apex classes, 12 LWCs, 87 Aura components, 68 Visualforce pages, 44 record-triggered/auto-launched Flows, 33 validation rules, 12 permission sets, ~264 test classes.

---

## 2. Tech-stack & layering at a glance

| Layer | Implementation |
|---|---|
| **Data model** | 59 custom objects (`__c`), 6 custom metadata types (`__mdt`), 1 platform event (`CtiNotification__e`). Mostly **Private** sharing for sensitive objects, ControlledByParent for child line items. |
| **Business logic** | Apex triggers → handler classes → service/helper classes. Recursion guarded by static bypass flags (`bypassTrigger`, `Utility.runLeadTrigger`) and custom-label gates (`label.RS_Trigger`, `label.Enable_Trigger`). |
| **Async** | `Database.Batchable` (17 batches), `Schedulable` (13 schedulers), `Queueable` (5 queueables), `@future` for callouts. |
| **Automation (declarative)** | 44 Flows — all AutoLaunched/Record-Triggered. No legacy Workflow Rules or Process Builder in use. |
| **UI** | Hybrid: legacy **Aura (87)** for complex booking/document-gen workflows; **LWC (12)** for newer flows (CP form, EOI, payments, query escalation, lead-extension). Visualforce mostly retained as **PDF templates** (~30+) and portal pages. |
| **Sharing** | Manual sharing centralised in `manulaSharingClass`, `RelatedSourceSharingService`, `ChannelPartnerSharingHelper`. Visibility for Related Source is gated by an `Is_Locked__c` flag. |
| **Integrations** | HTTP callouts (Queueables/@future) to WhatsApp, SFMC (Marketing Cloud), MCube, SMS/Email gateways, and an external PDF service. |
| **Security** | Permission-set-driven (no custom profiles). `Pre_Sales` is the primary role. MFA permission set + encrypted-field access set. |

---

## 3. Core entities (the data backbone)

Listed in funnel order. Field counts indicate complexity.

| # | Object | Sharing | Fields | Role |
|---|---|---|---|---|
| 1 | `Lead` (std) | Private | — | Inbound enquiry capture. |
| 2 | `Related_Source__c` | Private | **372** | The *real* opportunity record in this org — every channel/source/duplicate spawns one. Hub for assignment, locking, sharing, expiry. |
| 3 | `Channel_Partner__c` | Private | 144 | Broker / partner network. |
| 4 | `Site_Visit__c` | Private | 144 | Property visit scheduling, OTP check-in, completion. |
| 5 | `Project__c` → `Plot__c` (Unit) → `Block__c` / `Car_Parking__c` | Private / ControlledByParent | 77 / 135 | Project & inventory hierarchy. |
| 6 | `Quote__c` | Private | 140 | Pricing proposal; supports approval workflow. |
| 7 | `Booking__c` | Private | **252** | The confirmed sale. Master of `Additional_Charges__c`, `Demand_Raised__c`, `Interest_Amount_Line_Item__c`. |
| 8 | `Customer_Master__c` | ReadWrite | — | Deduplicated customer / buyer registry. |
| 9 | `Payment_schedule__c` → `Receipt_Line_Item__c` | Private / CBP | 54 / 17 | Milestone payments. |
| 10 | `Invoice__c` → `Invoice_Line_Item__c`, `Receipt__c`, `Payment__c` → `Payment_Line_Item__c`, `Refund__c` | Mixed | — | Billing, receipts, refunds. |
| 11 | `Inspection__c` → `Snag_List__c` | ReadWrite / CBP | 12 | Handover quality control. |
| 12 | `Customer_Query__c`, `Support_Ticket__c` | ReadWrite | 23 / 13 | Customer service. |

**Supporting clusters**
- **Activity:** `Call_Detail__c`, `Call_Comments__c`, `Follow_up__c`, `CRM_Comment__c`.
- **Notifications:** `Notification__c`, `Notification_Subscriber__c`, `Customer_Portal_Notification__c` (+ subscribers), `Announcement__c`.
- **Rewards/Commissions:** `Reward__c`, `Reward_Criteria__c`, `Commission_Slab__c`, `CP_Rewards__c`, `Commission_earned__c`, `Referral__c`.
- **Config / pricing:** `Interest_Percentage__c`, `Discount_Limit__c`, `Project_Discount_Limit__c`, `Master_Payment_Schedule__c`, `Payment_Plan__c`, `Source_Bifurcation__c`, `Round_Robin__c` + `Round_Robin_Member__c`, `Marketing_Campaign__c`, `Campaign__c`.
- **System:** `Apex_Log__c`, `Logged_in_Device__c`, `Report_Summary__c`, `Security_Register__c`, `MCUBE_Object_Api__c`, `Param_Mapping__c`.
- **Custom Metadata:** `Country_Code_Mapping__mdt`, `Lead_Assignment_Config__mdt`, `Project_Name_Mappings__mdt`, `Query_Escalation_Config__mdt`, `GRE_User__mdt`, `Mcube__mdt`.

---

## 4. Primary business flows

### 4.1 Lead → Related Source → Site Visit → Booking → Payments
```
 Inbound capture                Owner & sharing             Engage & convert            Confirm & settle
 ─────────────────              ───────────────             ────────────────            ──────────────────
 Lead (web/CP/portal/           Related_Source__c           Site_Visit__c               Booking__c
   call/EOI)                     (RoundRobinHandler           (round-robin,               (BookingTrigger →
   ↓                              + manual sharing,            OTP, reminders,              Demand_Raised__c,
 SLeadTrigger →                   Is_Locked__c gate,           CP/RM notifications)         Payment_schedule__c,
 RelatedSourceHandler             expiry & re-engage)         ↓                            Customer_Master__c)
                                  ↓                          Quote__c (approval)          ↓
                                  Notifications &             ↓                          Receipt__c → approval
                                  WhatsApp/SMS via JB         pushToSales                 → Invoice__c
                                                                                          ↓
                                                                                          Inspection__c →
                                                                                          handover docs
```

### 4.2 Channel Partner lifecycle
CP self-registration (LWC `channelPartnerForm` / VF `CP_Form`) → approval (`ChannelPartnerTriggerHandler.submitForApproval`) → docs pending/submitted → training scheduled/completed → activation → password set & welcome → CP can register leads (`cpLeadRegistrationForm`), submit demands, view payments. Owner / Sourcing-RM sharing managed by `ChannelPartnerSharingHelper`.

### 4.3 Customer service & escalation
`Customer_Query__c` (in) → `CustomerQueryAssignmentService` routes → `CustomerQueryEscalationService` + `CustomerQueryEscalationBatch` walks the `Query_Escalation_Config__mdt` ladder (TL → CRM_HOD → CFO → CEO) → notifications via `CCNotificationTriggerHandler`.

### 4.4 Document generation (Aura → VF templates → external PDF service)
Aura "Generate*" components (SaleAgreement, AllotmentLetter, KeyHandover, NOC, EOI, DemandNote, Receipt, ConsolidatedReceipt, TPA, LOU, Cancellation, etc.) invoke `DocumentandEmailController` which renders Visualforce templates and/or calls the external PDF service, then emails the result.

### 4.5 Async / scheduled fabric
Schedulers fire batches nightly / hourly: lead & RS expiry, CP deactivation, CP doc & training escalations, inspection reminders & escalations, payment-schedule reminders, agreement-payment reminders, post-SV follow-ups. Queueables handle MCube campaign push, demand emails, SMS, and report-summary PDFs.

---

## 5. Cross-cutting designs an architect should know

- **Recursion control** is *static-flag-based* per major object (`bypassTrigger` on `SiteVisitTriggerHandler`, `RelatedSourceHandler`; `Utility.runLeadTrigger` on `SLeadTrigger`) — there is no framework abstraction (no fflib / no Trigger Handler base class).
- **Sharing model is private + manual.** Related Source uses a unique `Is_Locked__c` flag to *suppress* sharing for duplicates / inactive records; Site Visit, Lead, Booking, Channel Partner each have their own `*__Share` insert paths in `manulaSharingClass`. This is the org's main access-control mechanism and is fragile to refactor.
- **Round-robin assignment** is a custom Apex implementation (`RoundRobinHandler`) backed by `Round_Robin__c` / `Round_Robin_Member__c` + `Lead_Assignment_Config__mdt`, used for both Lead and Related Source — and a separate path for Site Visit.
- **mCube / Journey Builder integration** flows through wrapper auto-launched flows (`JBSystemFlow_*` and `JBSystem_*_RecordFlow`) on Call_Detail, Related_Source, and Site_Visit. The integration secrets/config live in `Mcube__mdt`.
- **Outbound notifications** are split across (a) flows that create `tdc_tsw__Message__c` records for a third-party SMS/WhatsApp provider, (b) `WhatsAppBulkSender`/`WhatsAppTriggerHandler` direct callouts, and (c) custom notifications via `NotificationController`.
- **Testing posture:** ~1:1 test-class-per-class, but production code has many `Test.isRunningTest()` branches that bypass callouts and async — meaning unit tests skip large slices of real behaviour.
- **Hotspots / risk areas:** `RelatedSourceTrigger` (~1,081 LOC) and `CallDetailTrigger` (~470 LOC) carry too much inline logic; `Related_Source__c` (372 fields) and `Booking__c` (252 fields) are extreme-width objects that are likely near soft limits and tax page-layout / report design.

---

## 6. Permission & UI surface

- **Apps & utility bars:** ~18 utility-bar flexipages indicate the org runs several Console apps (LightningSales, LightningService, EasySales, MediaAdSales, mCube managed, Zuari custom).
- **Record pages:** 67 flexipages, with the heaviest customisation on Related_Source (178 KB), Lead (157 KB), Booking (140 KB), Channel_Partner (94 KB) — these are the pages real users live in.
- **Permission sets:** `Pre_Sales` (140 KB — sweeping Apex-class access) + `Pre_Sales_Permission` cover the main user population; the rest are integration / MFA / managed-package boilerplate. No custom profiles.
- **Portals:** Two Communities — a customer portal (Login/SelfReg/Confirm/Landing/Template VF pages) and a CP-facing surface (LWC + VF) for lead registration and payments.

---

## 7. Where the org is heading (inferred from the codebase)

- Migration from Aura → LWC is in-progress but not complete; document-generation and call-center workflows remain on Aura.
- Visualforce is being kept *only* for PDF templates and portal pages; new transactional UI is LWC.
- Custom Metadata is starting to absorb config that used to live in code (Country codes, query escalation ladder, assignment, mCube creds).
- Sharing logic has been growing case-by-case rather than via a unified model — a future consolidation pass on `manulaSharingClass` + `RelatedSourceSharingService` + `ChannelPartnerSharingHelper` would reduce drift.

---

## 8. How to validate / use this document

- Open `/home/user/Zuari---New-Sbox/force-app/main/default/objects/` and spot-check the 12 core objects above against §3.
- Open `/triggers/` — confirm the 28 triggers in §2/§5 and that each has a corresponding `*Handler` in `/classes/`.
- Open `/flows/` — confirm the 44 flows and that none are old `Workflow` or Process Builder.
- Cross-reference §5 sharing claims against `manulaSharingClass.cls`, `RelatedSourceSharingService.cls`, `ChannelPartnerSharingHelper.cls`.
- Use the funnel diagram in §4.1 as the canonical map when discussing any new feature — every feature in this org slots into one of those four columns.
