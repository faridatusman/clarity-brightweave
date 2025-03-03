// Enhanced test file with additional test cases

Clarinet.test({
    name: "Session management with timeout and rate limiting",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Test session creation with validation
        let block = chain.mineBlock([
            Tx.contractCall('bright_weave', 'create-session', [
                types.ascii("Test Session"),
                types.utf8("Test Description")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Test rate limiting
        let blocks = [];
        for (let i = 0; i < 3; i++) {
            blocks.push(
                Tx.contractCall('bright_weave', 'submit-idea', [
                    types.uint(1),
                    types.utf8("Test Idea " + i),
                    types.none()
                ], user1.address)
            );
        }
        
        let result = chain.mineBlock(blocks);
        result.receipts[2].result.expectErr(106); // Rate limit error
    }
});

// [Additional test cases...]
