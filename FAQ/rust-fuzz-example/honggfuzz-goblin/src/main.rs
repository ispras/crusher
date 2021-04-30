use goblin::Object;

#[cfg(feature="coverage")]
use goblin::error;


#[cfg(not(feature="coverage"))]
fn main () {
    use honggfuzz::fuzz;

    loop {
        fuzz!(|data: &[u8]| {
            let _ =Object::parse(data);
        });
    }
}

#[cfg(feature="coverage")]
fn main () -> error::Result<()> {
    use std::path::Path;
    use std::env;
    use std::fs;

    for (i, arg) in env::args().enumerate() {
        if i == 1 {
            let path = Path::new(arg.as_str());
            let data = fs::read(path)?;
            let _ =Object::parse(&data);
        }
    }
    Ok(())
}
