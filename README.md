# Tontine
A toy Solidity implementation of the tontine financial instrument. 

# What is a tontine?

The tontine is an archaic financial instrument originally designed as a retirement investment scheme.

There are differences in design but in this implementation it works like so:

1) Every investor pays a sum of money into the tontine.
2) The money is invested in an agreed-upon target when the tontine begins.
3) Each investor receives a proportionate share of the annuity on their capital invested.
4) When an investor dies their share of capital is devolved to the other participants equally.
5) The final surviving investor wraps up the tontine and is returned the full sum of money invested.

It is a fantastically bad idea to engage in this - every participant has a direct financial incentive to ensure the early demise of every other participant.

# Why is this a toy?

There's no current method to genuinely verify identity on the Ethereum blockchain, i.e. to provide proof-of-life. Authentication can only ever prove that a participant has possession of the originally used private key. Given that each participant is financially incentivised to maintain their participation, it's inevitable that participants will either automate their proof-of-life or distribute their key to a trusted party before death.