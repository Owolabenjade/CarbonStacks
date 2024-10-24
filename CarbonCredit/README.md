# Carbon Credits Smart Contract

The Carbon Credits Smart Contract allows environmental projects to issue carbon credits after verification by approved verifiers. Users can trade these credits or retire them to offset their carbon footprint. The contract maintains a transparent record of all transactions and verifications, ensuring that each carbon credit is accounted for and only used once.

## Features

- **Project Registration**: Authorized entities can register new environmental projects.
- **Credit Minting**: Verified projects can mint new carbon credits.
- **Credit Transfer**: Users can transfer carbon credits to others.
- **Credit Retirement**: Users can retire credits to offset emissions.
- **Verifiers Management**: The contract manages verifiers who are authorized to validate projects.
- **Verification Checkpoints**: Verifiers submit checkpoints to maintain the integrity of projects.
- **Transparency and Accountability**: All transactions and verifications are recorded on the blockchain.

## Key Components

- **Projects**: Environmental initiatives registered on the platform.
- **Carbon Credits**: Tokens representing a unit of carbon offset.
- **Verifiers**: Authorized entities that validate projects and checkpoints.
- **Balances**: Records of carbon credit holdings for each user.
- **Retired Credits**: Records of credits that have been retired and cannot be used again.
- **Listings**: Offers to sell carbon credits at a specified price.

## Functions

### Public Functions

- **add-verifier(verifier)**: Adds a new verifier to the system (only callable by the contract owner).
- **register-project(name, location)**: Registers a new environmental project (only callable by the contract owner).
- **mint-credits(amount, project-id, recipient)**: Mints new carbon credits for a project to a recipient (verifier only).
- **transfer(amount, recipient)**: Transfers carbon credits to another user.
- **create-listing(amount, price)**: Creates a new listing to sell credits.
- **retire-credits(amount, project-id, purpose, beneficiary)**: Retires credits to offset emissions.
- **register-verifier-credentials(verifier, organization, certification, valid-until)**: Registers verifier credentials (only callable by the contract owner).
- **submit-verification-checkpoint(project-id, checkpoint-type, details, evidence-hash)**: Verifiers submit checkpoints for projects.
- **approve-checkpoint(project-id, checkpoint-id)**: Approves a verification checkpoint (verifier only).

### Read-Only Functions

- **get-total-supply()**: Returns the total number of minted credits.
- **get-project(project-id)**: Retrieves details of a project.
- **get-project-credits(project-id)**: Returns the total credits for a project.
- **get-active-listing-ids(start, end)**: Retrieves active listings within a range.
- **get-retirement-details(retirement-id)**: Retrieves details of retired credits.
- **get-project-retired-amount(project-id)**: Returns the total retired credits for a project.
- **get-total-retired()**: Returns the total number of retired credits.
- **verify-retirement(retirement-id)**: Verifies if credits have been retired.
- **get-retirement-history(owner, start, end)**: Retrieves the retirement history of a user.
- **get-verifier-credentials(verifier)**: Retrieves verifier credentials.
- **get-checkpoint-details(project-id, checkpoint-id)**: Retrieves details of a checkpoint.
- **get-project-verification-status(project-id)**: Retrieves the verification status of a project.
- **is-verification-due(project-id)**: Checks if a project is due for verification.

## Use Case

**Scenario**: An environmental organization, GreenFuture, wants to offset carbon emissions by supporting a reforestation project.

1. **Project Registration**:
   - The contract owner registers a new project called "Rainforest Restoration" located in the Amazon.
   - `register-project("Rainforest Restoration", "Amazon Rainforest")`

2. **Verifier Addition**:
   - The contract owner adds an approved verifier, EcoVerify, to the system.
   - `add-verifier('SP2J...')` (EcoVerify's principal address)

3. **Verifier Credential Registration**:
   - EcoVerify registers their credentials.
   - `register-verifier-credentials('SP2J...', "EcoVerify Inc.", "ISO 14064-3", valid-until-block-height)`

4. **Credit Minting**:
   - EcoVerify verifies the project and mints 10,000 carbon credits to the project's account.
   - `mint-credits(u10000, u1, 'SP3K...')` (Project's principal address)

5. **Credit Transfer**:
   - The project transfers 2,000 credits to GreenFuture in exchange for funding.
   - `transfer(u2000, 'SP4M...')` (GreenFuture's principal address)

6. **Credit Retirement**:
   - GreenFuture decides to retire 1,500 credits to offset their annual emissions.
   - `retire-credits(u1500, u1, "Offsetting 2023 emissions", "GreenFuture Corp.")`

7. **Verification Checkpoint Submission**:
   - EcoVerify submits a quarterly verification checkpoint for the project.
   - `submit-verification-checkpoint(u1, CHECKPOINT-QUARTERLY, "Quarterly audit completed", evidence-hash)`

8. **Checkpoint Approval**:
   - Another verifier approves the submitted checkpoint.
   - `approve-checkpoint(u1, u2)`

9. **Transparency and Audit**:
   - Anyone can verify the retirement of credits by GreenFuture.
   - `get-retirement-details(u1)`

This use case demonstrates how organizations can participate in the carbon credit market using the smart contract, ensuring that their contributions are transparent and verifiable.

## Getting Started

To interact with the Carbon Credits Smart Contract:

1. **Prerequisites**:
   - Install a Clarity-compatible blockchain platform (e.g., Blockstack).
   - Set up a development environment for deploying and testing Clarity smart contracts.

2. **Deployment**:
   - Deploy the smart contract to the blockchain network.
   - Ensure the deployer becomes the contract owner.

3. **Interaction**:
   - Use Clarity-compatible tools or SDKs to call the contract functions.
   - Ensure that only authorized entities perform restricted actions (e.g., adding verifiers).

4. **Testing**:
   - Write unit tests for contract functions using the Clarity testing framework.
   - Simulate different scenarios to ensure the contract behaves as expected.

## Security Considerations

- **Input Validation**: The contract includes extensive input validation to prevent invalid or malicious data from affecting the system.
- **Access Control**: Certain functions are restricted to the contract owner or verifiers to prevent unauthorized actions.
- **Immutable Records**: Once credits are retired, they cannot be transferred again, preventing double-counting.
- **Data Integrity**: Verification checkpoints and evidence hashes ensure that project data remains trustworthy.

**Note**: Users should carefully manage their private keys and only interact with trusted verifiers and projects to maintain the integrity of the system.

---

**Disclaimer**: This smart contract is provided "as is" without warranty of any kind. The author (me) is not responsible for any losses or damages resulting from its use. Users are advised to conduct thorough testing and audits before deploying it in a production environment.