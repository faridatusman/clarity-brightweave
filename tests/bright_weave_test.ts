import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new brainstorming session",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const title = "Product Brainstorm";
        const description = "Brainstorming session for new product features";
        
        let block = chain.mineBlock([
            Tx.contractCall('bright_weave', 'create-session', [
                types.ascii(title),
                types.utf8(description)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Verify session details
        let getSession = chain.callReadOnlyFn(
            'bright_weave',
            'get-session',
            [types.uint(1)],
            deployer.address
        );
        
        let session = getSession.result.expectSome().expectTuple();
        assertEquals(session['title'], types.ascii(title));
        assertEquals(session['owner'], deployer.address);
    }
});

Clarinet.test({
    name: "Can add collaborators and submit ideas",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator = accounts.get('wallet_1')!;
        
        // Create session
        let block = chain.mineBlock([
            Tx.contractCall('bright_weave', 'create-session', [
                types.ascii("Test Session"),
                types.utf8("Test Description")
            ], deployer.address),
            
            // Add collaborator
            Tx.contractCall('bright_weave', 'add-collaborator', [
                types.uint(1),
                types.principal(collaborator.address)
            ], deployer.address)
        ]);
        
        block.receipts.map(receipt => receipt.result.expectOk());
        
        // Submit idea as collaborator
        let ideaBlock = chain.mineBlock([
            Tx.contractCall('bright_weave', 'submit-idea', [
                types.uint(1),
                types.utf8("New feature idea")
            ], collaborator.address)
        ]);
        
        ideaBlock.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can vote on ideas",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator = accounts.get('wallet_1')!;
        
        // Setup session and idea
        let setup = chain.mineBlock([
            Tx.contractCall('bright_weave', 'create-session', [
                types.ascii("Vote Test"),
                types.utf8("Test Description")
            ], deployer.address),
            Tx.contractCall('bright_weave', 'add-collaborator', [
                types.uint(1),
                types.principal(collaborator.address)
            ], deployer.address),
            Tx.contractCall('bright_weave', 'submit-idea', [
                types.uint(1),
                types.utf8("Votable idea")
            ], deployer.address)
        ]);
        
        // Vote on idea
        let voteBlock = chain.mineBlock([
            Tx.contractCall('bright_weave', 'vote-idea', [
                types.uint(1)
            ], collaborator.address)
        ]);
        
        voteBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify vote count
        let getIdea = chain.callReadOnlyFn(
            'bright_weave',
            'get-idea',
            [types.uint(1)],
            deployer.address
        );
        
        let idea = getIdea.result.expectSome().expectTuple();
        assertEquals(idea['votes'], types.uint(1));
    }
});