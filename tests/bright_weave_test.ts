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
    name: "Can create milestones and enable milestone voting",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('bright_weave', 'create-session', [
                types.ascii("Milestone Test"),
                types.utf8("Test Description")
            ], deployer.address),
            
            Tx.contractCall('bright_weave', 'create-milestone', [
                types.uint(1),
                types.ascii("Q1 Release"),
                types.utf8("First quarter release features")
            ], deployer.address),
            
            Tx.contractCall('bright_weave', 'enable-milestone-voting', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts.map(receipt => receipt.result.expectOk());
        
        let getMilestone = chain.callReadOnlyFn(
            'bright_weave',
            'get-milestone',
            [types.uint(1)],
            deployer.address
        );
        
        let milestone = getMilestone.result.expectSome().expectTuple();
        assertEquals(milestone['title'], types.ascii("Q1 Release"));
    }
});

Clarinet.test({
    name: "Can vote on ideas for milestones",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator = accounts.get('wallet_1')!;
        
        let setup = chain.mineBlock([
            Tx.contractCall('bright_weave', 'create-session', [
                types.ascii("Milestone Vote Test"),
                types.utf8("Test Description")
            ], deployer.address),
            
            Tx.contractCall('bright_weave', 'add-collaborator', [
                types.uint(1),
                types.principal(collaborator.address)
            ], deployer.address),
            
            Tx.contractCall('bright_weave', 'submit-idea', [
                types.uint(1),
                types.utf8("Milestone idea")
            ], deployer.address),
            
            Tx.contractCall('bright_weave', 'enable-milestone-voting', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        let voteBlock = chain.mineBlock([
            Tx.contractCall('bright_weave', 'vote-idea-for-milestone', [
                types.uint(1)
            ], collaborator.address)
        ]);
        
        voteBlock.receipts[0].result.expectOk().expectBool(true);
        
        let getIdea = chain.callReadOnlyFn(
            'bright_weave',
            'get-idea',
            [types.uint(1)],
            deployer.address
        );
        
        let idea = getIdea.result.expectSome().expectTuple();
        assertEquals(idea['milestone-votes'], types.uint(1));
    }
});
