/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* global getAssetRegistry getFactory emit */

/**
  * Create the insuree
  * @param {com.packt.quickstart.claim.Init} Init - the InitialApplication transaction
  * @transaction
  */
 async function Init(application) { // eslint-disable-line no-unused-vars
     const factory = getFactory();
     const namespace = 'com.packt.quickstart.claim';

     const insuree = factory.newResource(namespace, 'Insuree', application.insureeId);
     insuree.firstName = application.firstName;;
     insuree.lastName = application.lastName;
     insuree.ssn = application.ssn;;
     insuree.policyNumber = application.policyNumber;;
     const participantRegistry = await getParticipantRegistry(insuree.getFullyQualifiedType());
     await participantRegistry.add(insuree);

     // emit event
     const initEventEvent = factory.newEvent(namespace, 'InitEvent');
     initEventEvent.insuree = insuree;
     emit(initEventEvent);
 }
/**
  * insuree report lost item
  * @param {com.packt.quickstart.claim.ReportLost} ReportLost - the ReportLost transaction
  * @transaction
  */
 async function ReportLost(request) { // eslint-disable-line no-unused-vars
     const factory = getFactory();
     const namespace = 'com.packt.quickstart.claim';
     let claimId = request.claimId;
     let desc = request.desc;
     let insureeId = request.insureeId;
     let brokerId = request.brokerId;
   
     const claim = factory.newResource(namespace, 'Claim', claimId);
     claim.desc = desc;
     claim.status = "ReportLost";
     claim.insureeId = insureeId;
     claim.brokerId = brokerId;
     claim.insurerId = "";
     claim.comment = "";
     claim.processAt = (new Date()).toString();
     const claimRegistry = await getAssetRegistry(claim.getFullyQualifiedType());
     await claimRegistry.add(claim);

     // emit event
     const reportLostEvent = factory.newEvent(namespace, 'ReportLostEvent');
     reportLostEvent.claim = claim;
     emit(reportLostEvent);
 }
/**
  * broker send Requested Info to insuree
  * @param {com.packt.quickstart.claim.RequestedInfo} RequestedInfo - the RequestedInfo transaction
  * @transaction
  */
 async function RequestedInfo(request) { // eslint-disable-line no-unused-vars
     const factory = getFactory();
     const namespace = 'com.packt.quickstart.claim';
     let claim = request.claim;
     if (claim.status !== 'ReportLost') {
         throw new Error ('This claim should be in ReportLost status');
     } 
     claim.status = 'RequestedInfo';
     claim.processAt = (new Date()).toString();
     const assetRegistry = await getAssetRegistry(request.claim.getFullyQualifiedType());
     await assetRegistry.update(claim);

     // emit event
     const requestedInfoEventEvent = factory.newEvent(namespace, 'RequestedInfoEvent');
     requestedInfoEventEvent.claim = claim;
     emit(requestedInfoEventEvent);
 }
/**
  * broker submit claim to insurer
  * @param {com.packt.quickstart.claim.SubmitClaim} SubmitClaim - the SubmitClaim transaction
  * @transaction
  */
 async function SubmitClaim(request) { // eslint-disable-line no-unused-vars
     const factory = getFactory();
     const namespace = 'com.packt.quickstart.claim';
     let claim = request.claim;
     if (claim.status !== 'RequestedInfo') {
         throw new Error ('This claim should be in RequestedInfo status');
     } 
     claim.status = 'SubmitClaim';
     claim.processAt = (new Date()).toString();
     const assetRegistry = await getAssetRegistry(request.claim.getFullyQualifiedType());
     await assetRegistry.update(claim);

     // emit event
     const submitClaimEvent = factory.newEvent(namespace, 'SubmitClaimEvent');
     submitClaimEvent.claim = claim;
     emit(submitClaimEvent);
 }
/**
  * insurer confirm broker claim submission
  * @param {com.packt.quickstart.claim.ConfirmClaimSubmission} ConfirmClaimSubmission - the ConfirmClaimSubmission transaction
  * @transaction
  */
 async function ConfirmClaimSubmission(request) { // eslint-disable-line no-unused-vars
     const factory = getFactory();
     const namespace = 'com.packt.quickstart.claim';
     let claim = request.claim;
     if (claim.status !== 'SubmitClaim') {
         throw new Error ('This claim should be in SubmitClaim status');
     } 
     claim.status = 'ConfirmClaimSubmission';
     claim.processAt = (new Date()).toString();
     const assetRegistry = await getAssetRegistry(request.claim.getFullyQualifiedType());
     await assetRegistry.update(claim);

     // emit event
     const confirmClaimSubmissionEvent = factory.newEvent(namespace, 'ConfirmClaimSubmissionEvent');
     confirmClaimSubmissionEvent.claim = claim;
     emit(confirmClaimSubmissionEvent);
 }
/**
  * insurer approve the claim
  * @param {com.packt.quickstart.claim.ApproveClaim} ApproveClaim - the ApproveClaim transaction
  * @transaction
  */
 async function ApproveClaim(request) { // eslint-disable-line no-unused-vars
     const factory = getFactory();
     const namespace = 'com.packt.quickstart.claim';
     let claim = request.claim;
     if (claim.status !== 'ConfirmClaimSubmission') {
         throw new Error ('This claim should be in ConfirmClaimSubmission status');
     } 
     claim.status = 'ApproveClaim';
     claim.processAt = (new Date()).toString();
     const assetRegistry = await getAssetRegistry(request.claim.getFullyQualifiedType());
     await assetRegistry.update(claim);

     // emit event
     const approveClaimEvent = factory.newEvent(namespace, 'ApproveClaimEvent');
     approveClaimEvent.claim = claim;
     emit(approveClaimEvent);
 }