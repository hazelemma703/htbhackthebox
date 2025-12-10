from qiskit import QuantumCircuit, transpile
from qiskit_aer import Aer

class Hyperlink:
    def __init__(self):
        self.backend = Aer.get_backend("qasm_simulator")

    def generate_circuit(self, instructions: str):
        circuit = QuantumCircuit(5)
        
        instructions = instructions.split(";")
        for instr in instructions:
            parts = instr.split(":")

            if len(parts) != 2:
                print(f"Invalid instruction: {instr}. Expected format: <gate>:<params>")
                print("Examples: H:<target> | CX:<control>,<target>")
                return None

            gate, params = parts

            try:
                params = [ int(p) for p in params.split(",") ]
            except:
                print("Quantum gate input parameters must be integers.") 
                print("Examples: H:0 | CX:0,1")
                return None

            if any(n >= circuit.num_qubits for n in params):
                print(f"Qubit indexes must be less than {circuit.num_qubits}")
                return None

            if len(params) == 1:
                if   gate == "H": circuit.h(params[0])
                elif gate == "S": circuit.s(params[0])
                elif gate == "T": circuit.t(params[0])
                elif gate == "X": circuit.x(params[0])
                else:
                    print(f"Quantum gate '{gate}' is invalid or unexpected with 1 parameter.")
                    return None

            elif len(params) == 2:
                if params[0] == params[1]:
                    print("Control and target qubits must be different.")
                    return None

                if   gate == "CX": circuit.cx(params[0], params[1])
                elif gate == "CY": circuit.cy(params[0], params[1])
                elif gate == "CZ": circuit.cz(params[0], params[1])
                else:
                    print(f"Quantum gate '{gate}' is invalid or unexpected with 2 parameters.")
                    return None

            else:
                print(f"Unsupported number of parameters ({len(params)}) for quantum gate '{gate}'.")
                return None
        
        circuit.measure_all()

        return circuit

    def initialize_hyperlink(self, instructions, shots = 256):
        if len(instructions) == 0:
            return False

        circuit = self.generate_circuit(instructions)

        if not circuit:
            return False

        compiled = transpile(circuit, self.backend)
        results = self.backend.run(compiled, shots = shots, memory = True).result()

        shares = [""] * 5
        
        for bits in results.get_memory():
            for i, bit in enumerate(bits[::-1]):
                shares[i] += bit

        shares = [ int(share, 2).to_bytes(32, byteorder = "big") for share in shares ]

        if any(set(share) in ({0}, {255}) for share in shares):
            return False

        if (
            shares[0] == shares[1] and
            shares[1] == shares[3] and
            shares[2] == shares[4] and
            shares[4] != shares[0]
        ):
            return True

        return False


def main():
    print("""
                 _             _       _      _         
                /\ \          / /\    / /\  /\ \        
               /  \ \        / / /   / / / /  \ \       
              / /\ \_\      / /_/   / / /_/ /\ \ \      
             / / /\/_/     / /\ \__/ / /___/ /\ \ \     
            / / / ______  / /\ \___\/ /\___\/ / / /     
           / / / /\_____\/ / /\/___/ /       / / /      
          / / /  \/____ / / /   / / /       / / /    _  
         / / /_____/ / / / /   / / /        \ \ \__/\_\ 
        / / /______\/ / / /   / / /          \ \___\/ / 
        \/___________/\/_/    \/_/            \/___/_/  
                                                
    """)

    print("Welcome to the Global Hyperlink Zone! The first quantum internet prototype by Qubitrix.")
    print("Please send the instructions to initialize the hyperlink.")

    hyperlink = Hyperlink()

    while True:
        instructions = input('Specify the instructions : ')

        init = hyperlink.initialize_hyperlink(instructions)

        if not init:
            print("Incorrect Hyperlink connection pattern. Try again.")
            continue

        print(f"Hyperlink initialized successfully! Connection ID: {open('flag.txt').read()}")


if __name__ == '__main__':
    main()
