// [Previous test imports and existing tests remain unchanged]

Clarinet.test({
    name: "Can pause and unpause sessions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('bright_weave', 'create-session', [
                types.ascii("Pause Test"),
                types.utf8("Test Description")
            ], deployer.address),
            
            Tx.contractCall('bright_weave', 'pause-session', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts.map(receipt => receipt.result.expectOk());
        
        let getStatus = chain.callReadOnlyFn(
            'bright_weave',
            'get-session-status',
            [types.uint(1)],
            deployer.address
        );
        
        let status = getStatus.result.expectOk().expectTuple();
        assertEquals(status['paused'], types.bool(true));
    }
});
